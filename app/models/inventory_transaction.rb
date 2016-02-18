class InventoryTransaction < ActiveRecord::Base
  actable 

  belongs_to :inventory_item
  validates :concept, :inventory_item, presence: true

  def self.search( params = {} )
    inventory_transactions = InventoryTransaction.order(created_at: :desc).all

    transaction_details = { 'inventory_transactions' => [] }

    inventory_transactions.each do |i|
      inventory_item = InventoryItem.find( i.inventory_item_id )
      transaction = InventoryTransaction.get_by_type( i.actable_id, i.actable_type )
      entry_exit_date = "CheckInTransaction" == i.actable_type ? transaction.entry_date : transaction.exit_date
      deliver_pickup_contact = "CheckInTransaction" == i.actable_type ? transaction.delivery_company_contact : transaction.pickup_company_contact
      transaction_details['inventory_transactions'].push({
        'inventory_item'  => {
            'name'          => inventory_item.name,
            'actable_type'  => inventory_item.actable_type,
            'status'        => inventory_item.get_status,
            'img'           => inventory_item.item_img(:medium)
        },
        'id'                      => i.id,
        'actable_type'            => i.actable_type,
        'quantity'                => i.quantity,
        'entry_exit_date'         => entry_exit_date,
        'deliver_pickup_contact'  => deliver_pickup_contact
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
            'status'        => inventory_item.get_status,
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
    transactions = CheckInTransaction.all.order(updated_at: :desc)
    check_ins = { 'inventory_transactions' => [] }

    transactions.each do |t|
      inventory_transaction = InventoryTransaction.find_by_actable_id( t.id )
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

  def self.get_by_type id, type
    if 'CheckInTransaction' == type 
      return CheckInTransaction.find( id )
    end

    if 'CheckOutTransaction' == type 
      return CheckOutTransaction.find( id )
    end
  end

end
