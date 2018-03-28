class InventoryTransaction < ActiveRecord::Base
  actable 

  belongs_to :inventory_item
  validates :concept, :inventory_item, presence: true

  def self.search( params = {}, user )
    if( User::CLIENT == user.role )
      client_user = ClientContact.find( user.actable_id )
      inventory_transactions = InventoryTransaction.eager_load(:inventory_item).where('inventory_item_id IN (?)', client_user.inventory_items_id ).order(created_at: :desc)
    else
      inventory_transactions = InventoryTransaction.all.order(created_at: :desc)
    end

    transaction_details = { 'inventory_transactions' => [] }

    inventory_transactions.each do |i|
      next if i.inventory_item_id.nil?

      inventory_item = InventoryItem.find( i.inventory_item_id )
      transaction = InventoryTransaction.get_by_type( i.actable_id, i.actable_type )
      entry_exit_date = "CheckInTransaction" == i.actable_type ? transaction.entry_date : transaction.exit_date
      deliver_pickup_contact = "CheckInTransaction" == i.actable_type ? transaction.delivery_company_contact : transaction.pickup_company_contact
      transaction_details['inventory_transactions'].push({
        'inventory_item'  => {
            'name'          => inventory_item.name,
            'actable_type'  => inventory_item.actable_type,
            'status'        => inventory_item.status_name,
            'img'           => inventory_item.item_img(:medium)
        },
        'id'                      => i.id,
        'actable_type'            => i.actable_type,
        'quantity'                => i.quantity,
        'entry_exit_date'         => entry_exit_date,
        'deliver_pickup_contact'  => deliver_pickup_contact,
        'additional_comments'     => i.additional_comments
      })
    end

    transaction_details
  end

  def self.better_search( keyword, user )
    unit_item = UnitItem.find_by_serial_number( keyword )
    if unit_item.present?
      inventory_items_id = InventoryItem.select(:id).where( 'actable_id = ? AND actable_type = ?', unit_item.id, 'UnitItem' ).pluck(:id)
      inventory_transactions = InventoryTransaction.eager_load(:inventory_item).where('inventory_item_id IN (?)', inventory_items_id).order(created_at: :desc)
      return get_formatted_transactions( inventory_transactions )
    end


    bundle_item_part = BundleItemPart.find_by_serial_number( keyword )
    if bundle_item_part.present?
      bundle_item = bundle_item_part.bundle_item
      inventory_items_id = InventoryItem.where( 'actable_id = ? AND actable_type = ?', bundle_item.id, 'BundleItem' ).pluck(:id)
      inventory_transactions = InventoryTransaction.eager_load(:inventory_item).where('inventory_item_id IN (?)', inventory_items_id).order(created_at: :desc)
      return get_formatted_transactions( inventory_transactions )
    end

    inventory_items_id = InventoryItem.where( 'name LIKE ? OR lower( barcode ) LIKE ?', "%#{keyword}%", "%#{keyword.downcase}%" ).pluck(:id)
    inventory_transactions = InventoryTransaction.eager_load(:inventory_item).where('inventory_item_id IN (?)', inventory_items_id).order(created_at: :desc)
    return get_formatted_transactions( inventory_transactions )
  end

  def self.get_formatted_transactions( transactions )
    transaction_details = { 'inventory_transactions' => [] }
    transactions.each do |i|
      next if i.inventory_item_id.nil?

      inventory_item = InventoryItem.find( i.inventory_item_id )
      transaction = InventoryTransaction.get_by_type( i.actable_id, i.actable_type )
      entry_exit_date = "CheckInTransaction" == i.actable_type ? transaction.entry_date : transaction.exit_date
      deliver_pickup_contact = "CheckInTransaction" == i.actable_type ? transaction.delivery_company_contact : transaction.pickup_company_contact
      transaction_details['inventory_transactions'].push({
        'inventory_item'  => {
            'id'            => inventory_item.id,
            'name'          => inventory_item.name,
            'actable_type'  => inventory_item.actable_type,
            'status'        => inventory_item.status_name,
            'img'           => inventory_item.item_img(:medium)
        },
        'id'                      => i.id,
        'actable_type'            => i.actable_type,
        'quantity'                => i.quantity,
        'entry_exit_date'         => entry_exit_date,
        'deliver_pickup_contact'  => deliver_pickup_contact,
        'additional_comments'     => i.additional_comments
      })
    end

    transaction_details
  end

  def get_details
    inventory_item = InventoryItem.find( self.inventory_item_id )
    transaction = InventoryTransaction.get_by_type( self.actable_id, self.actable_type )
    entry_exit_date = "CheckInTransaction" == self.actable_type ? transaction.entry_date : transaction.exit_date
    delivery_pickup_contact = "CheckInTransaction" == self.actable_type ? transaction.delivery_company_contact : transaction.pickup_company_contact
    delivery_pickup_company = "CheckInTransaction" == self.actable_type ? transaction.delivery_company : transaction.pickup_company
    details = { 'inventory_transaction' => {
        'inventory_item'  => {
            'name'          => inventory_item.name,
            'actable_type'  => inventory_item.actable_type,
            'status'        => inventory_item.status_name,
            'img'           => inventory_item.item_img(:medium)
        },
        'actable_type'            => self.actable_type,
        'quantity'                => self.quantity,
        'entry_exit_date'         => entry_exit_date,
        'delivery_pickup_contact' => delivery_pickup_contact,
        'delivery_pickup_company' => delivery_pickup_company,
        'concept'                 => concept,
        'additional_comments'     => additional_comments
      }  
    }
    details
  end

  def self.check_ins
    transactions = CheckInTransaction.all.order(updated_at: :desc).limit(10)
    check_ins = { 'inventory_transactions' => [] }

    transactions.each do |t|
      inventory_transaction = InventoryTransaction.find_by_actable_id( t.id )
      next if ! inventory_transaction.present?
      next if ! t.inventory_item_id.present?

      item = InventoryItem.find(t.inventory_item_id)
      check_ins['inventory_transactions'].push({
        'id'              => inventory_transaction.id,
        'concept'         => inventory_transaction.concept,
        'actable_type'    => item.actable_type,
        'entry_date'      => t.entry_date,
        'name'            => item.name,
        'item_type'       => item.item_type
      })
    end

    return check_ins
  end

  def self.check_outs
    transactions = CheckOutTransaction.all.order(updated_at: :desc)
    check_outs = { 'inventory_transactions' => [] }

    transactions.each do |t|
      item = InventoryItem.find(t.inventory_item_id)
      inventory_transaction = InventoryTransaction.where('actable_type = ? AND actable_id = ?', 'CheckOutTransaction', t.id).first
      check_outs['inventory_transactions'].push({ 
        'id'              => inventory_transaction.id,
        'concept'         => inventory_transaction.concept,
        'actable_type'    => item.actable_type,
        'exit_date'       => t.exit_date,
        'name'            => item.name,
        'item_type'       => item.item_type
      })
    end

    return check_outs
  end

  def self.check_outs_by_client client_user, limit=100
    client_projects = client_user.client.projects.pluck(:id)
    client_items_ids = InventoryItem.where('project_id IN (?)', client_projects).pluck(:id)

    transactions = CheckOutTransaction.where('inventory_item_id IN (?)', client_items_ids).order(updated_at: :desc).limit( limit )
    check_outs = { 'inventory_transactions' => [] }

    transactions.each do |t|
      item = InventoryItem.find(t.inventory_item_id)
      inventory_transaction = InventoryTransaction.where('actable_type = ? AND actable_id = ?', 'CheckOutTransaction', t.id).first
      check_outs['inventory_transactions'].push({ 
        'id'              => inventory_transaction.id,
        'concept'         => inventory_transaction.concept,
        'actable_type'    => item.actable_type,
        'exit_date'       => t.exit_date,
        'name'            => item.name,
        'item_type'       => item.item_type
      })
    end

    return check_outs
  end

  def self.get_by_type id, type
    if 'CheckInTransaction' == type 
      return CheckInTransaction.find( id )
    end

    if 'CheckOutTransaction' == type 
      return CheckOutTransaction.find( id )
    end
  end

end
