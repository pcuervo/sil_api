class InventoryTransaction < ActiveRecord::Base
  actable

  belongs_to :inventory_item
  validates :concept, :inventory_item, presence: true

  def self.search(_params = {}, user)
    if User::CLIENT == user.role
      client_user = ClientContact.find(user.actable_id)
      inventory_transactions = InventoryTransaction.eager_load(:inventory_item).where(
        'inventory_item_id IN (?)',
        client_user.inventory_items_id
      ).order(created_at: :desc)
    else
      inventory_transactions = InventoryTransaction.all.order(created_at: :desc)
    end

    transaction_details = { 'inventory_transactions' => [] }

    inventory_transactions.each do |i|
      next if i.inventory_item_id.nil?

      inventory_item = InventoryItem.find(i.inventory_item_id)
      transaction = InventoryTransaction.get_by_type(i.actable_id, i.actable_type)
      entry_exit_date = i.actable_type == 'CheckInTransaction' ? transaction.entry_date : transaction.exit_date
      deliver_pickup_contact = i.actable_type == 'CheckInTransaction' ? transaction.delivery_company_contact : transaction.pickup_company_contact
      transaction_details['inventory_transactions'].push(
        'inventory_item' => {
          'name'         => inventory_item.name,
          'actable_type' => inventory_item.actable_type,
          'status'       => inventory_item.get_status,
          'img'          => inventory_item.item_img(:medium)
        },
        'id'                     => i.id,
        'actable_type'           => i.actable_type,
        'quantity'               => i.quantity,
        'entry_exit_date'        => entry_exit_date,
        'deliver_pickup_contact' => deliver_pickup_contact,
        'additional_comments'    => i.additional_comments
      )
    end

    transaction_details
  end

  def self.better_search(keyword, _user)
    unit_item = UnitItem.find_by(serial_number: keyword)
    if unit_item.present?
      inventory_items_id = InventoryItem.select(:id).where('actable_id = ? AND actable_type = ?', unit_item.id, 'UnitItem').pluck(:id)
      inventory_transactions = InventoryTransaction.eager_load(:inventory_item).where('inventory_item_id IN (?)', inventory_items_id).order(created_at: :desc)
      return get_formatted_transactions(inventory_transactions)
    end

    inventory_items_id = InventoryItem.where('lower(name) LIKE ? OR lower( barcode ) LIKE ? OR lower(serial_number) LIKE ?', "%#{keyword.downcase}%", "%#{keyword.downcase}%", "%#{keyword.downcase}%").pluck(:id)
    inventory_transactions = InventoryTransaction.eager_load(:inventory_item).where('inventory_item_id IN (?)', inventory_items_id).order(created_at: :desc)
    get_formatted_transactions(inventory_transactions)
  end

  def self.get_formatted_transactions(transactions)
    transaction_details = { 'inventory_transactions' => [] }
    transactions.each do |i|
      next if i.inventory_item_id.nil?

      inventory_item = InventoryItem.find(i.inventory_item_id)
      transaction = InventoryTransaction.get_by_type(i.actable_id, i.actable_type)
      entry_exit_date = i.actable_type == 'CheckInTransaction' ? transaction.entry_date : transaction.exit_date
      deliver_pickup_contact = i.actable_type == 'CheckInTransaction' ? transaction.delivery_company_contact : transaction.pickup_company_contact

      transaction = if i.actable_type == 'CheckOutTransaction'
                      CheckOutTransaction.find(i.actable_id)
                    else
                      CheckInTransaction.find(i.actable_id)
                    end
      folio = transaction.folio

      transaction_details['inventory_transactions'].push(
        'inventory_item' => {
          'id'            => inventory_item.id,
          'name'          => inventory_item.name,
          'serial_number' => inventory_item.serial_number,
          'status'        => inventory_item.status_name,
          'quantity'      => inventory_item.quantity,
          'img'           => inventory_item.item_img(:medium)
        },
        'id'                     => i.id,
        'actable_type'           => i.actable_type,
        'quantity'               => i.quantity,
        'entry_exit_date'        => entry_exit_date,
        'deliver_pickup_contact' => deliver_pickup_contact,
        'additional_comments'    => i.additional_comments,
        'folio'                  => folio
      )
    end

    transaction_details
  end

  def get_details
    inventory_item = InventoryItem.find(inventory_item_id)
    transaction = InventoryTransaction.get_by_type(actable_id, actable_type)
    entry_exit_date = actable_type == 'CheckInTransaction' ? transaction.entry_date : transaction.exit_date
    delivery_pickup_contact = actable_type == 'CheckInTransaction' ? transaction.delivery_company_contact : transaction.pickup_company_contact
    delivery_pickup_company = actable_type == 'CheckInTransaction' ? transaction.delivery_company : transaction.pickup_company
    details = { 'inventory_transaction' => {
      'inventory_item' => {
        'name'         => inventory_item.name,
        'actable_type' => inventory_item.actable_type,
        'status'       => inventory_item.get_status,
        'img'          => inventory_item.item_img(:medium)
      },
      'actable_type'            => actable_type,
      'quantity'                => quantity,
      'entry_exit_date'         => entry_exit_date,
      'delivery_pickup_contact' => delivery_pickup_contact,
      'delivery_pickup_company' => delivery_pickup_company,
      'concept'                 => concept,
      'additional_comments'     => additional_comments
    } }
    details
  end

  def self.by_folio(folio)
    transactions = InventoryTransaction.none
    transactions += CheckInTransaction.where('UPPER(folio) LIKE ? ', "%#{folio.upcase}%")
    transactions += CheckOutTransaction.where('UPPER(folio) LIKE ? ', "%#{folio.upcase}%")

    get_formatted_transactions(transactions)
  end

  def self.check_ins
    check_in_transactions = CheckInTransaction.all.order(updated_at: :desc).limit(10)
    check_ins = { 'inventory_transactions' => [] }

    check_in_transactions.each do |t|
      inventory_transaction = InventoryTransaction.find_by(actable_id: t.id)
      next if inventory_transaction.blank?
      next if t.inventory_item_id.blank?

      item = InventoryItem.find(t.inventory_item_id)
      check_ins['inventory_transactions'].push(
        'id'           => inventory_transaction.id,
        'concept'      => inventory_transaction.concept,
        'actable_type' => item.actable_type,
        'entry_date'   => t.entry_date,
        'name'         => item.name,
        'item_type'    => item.item_type
      )
    end

    check_ins
  end

  def self.check_outs
    transactions = CheckOutTransaction.all.order(updated_at: :desc)
    check_outs = { 'inventory_transactions' => [] }

    transactions.each do |t|
      item = InventoryItem.find(t.inventory_item_id)
      inventory_transaction = InventoryTransaction.where('actable_type = ? AND actable_id = ?', 'CheckOutTransaction', t.id).first
      check_outs['inventory_transactions'].push(
        'id'           => inventory_transaction.id,
        'concept'      => inventory_transaction.concept,
        'actable_type' => item.actable_type,
        'exit_date'    => t.exit_date,
        'name'         => item.name,
        'item_type'    => item.item_type
      )
    end

    check_outs
  end

  def self.check_outs_by_client(client_user, limit = 100)
    client_projects = client_user.client.projects.pluck(:id)
    client_items_ids = InventoryItem.where('project_id IN (?)', client_projects).pluck(:id)

    transactions = CheckOutTransaction.where('inventory_item_id IN (?)', client_items_ids).order(updated_at: :desc).limit(limit)
    check_outs = { 'inventory_transactions' => [] }

    transactions.each do |t|
      item = InventoryItem.find(t.inventory_item_id)
      inventory_transaction = InventoryTransaction.where('actable_type = ? AND actable_id = ?', 'CheckOutTransaction', t.id).first
      check_outs['inventory_transactions'].push(
        'id'           => inventory_transaction.id,
        'concept'      => inventory_transaction.concept,
        'actable_type' => item.actable_type,
        'exit_date'    => t.exit_date,
        'name'         => item.name,
        'item_type'    => item.item_type
      )
    end

    check_outs
  end

  def self.get_by_type(id, type)
    return CheckInTransaction.find(id) if type == 'CheckInTransaction'

    return CheckOutTransaction.find(id) if type == 'CheckOutTransaction'
  end

  def self.next_checkout_folio
    return 'FS-0000001' if CheckOutTransaction.last.blank?

    last_folio = CheckOutTransaction.last.folio
    return 'FS-0000001' if last_folio == '-'

    next_folio_num = self.next_folio_num(last_folio)

    'FS-' + next_folio_num
  end

  def self.next_checkin_folio
    return 'FE-0000001' if CheckInTransaction.last.blank?

    last_folio = CheckInTransaction.last.folio
    return 'FE-0000001' if last_folio == '-'

    next_folio_num = self.next_folio_num(last_folio)

    'FE-' + next_folio_num
  end

  def self.next_folio_num(last_folio)
    total_digits = 7
    splitted = last_folio.split('-')
    next_folio_num = splitted[1].to_i + 1

    next_folio_num = '0' + next_folio_num.to_s while next_folio_num.to_s.length < total_digits
    next_folio_num
  end
end
