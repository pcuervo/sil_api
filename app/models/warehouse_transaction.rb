class WarehouseTransaction < ActiveRecord::Base
  belongs_to :inventory_item
  belongs_to :warehouse_location

  # Transaction Concepts
  ENTRY = 1
  RELOCATION = 2
  WITHDRAW = 3

  def self.get_details
    warehouse_transactions = WarehouseTransaction.all.order(created_at: :desc).limit(50)

    warehouse_transaction_details = { 'warehouse_transactions' => [] }
    warehouse_transactions.each do |wt|
      inventory_item = InventoryItem.find( wt.inventory_item_id )
      location = WarehouseLocation.find( wt.warehouse_location_id )
      warehouse_transaction_details['warehouse_transactions'].push({
        'item_name'   => inventory_item.name,
        'location_id' => location.id,
        'location'    => location.name,
        'rack_id'     => location.warehouse_rack.id,
        'rack'        => location.warehouse_rack.name,
        'concept'     => get_concept_description( wt.concept ),
        'created_at'  => wt.created_at,
        'units'       => wt.units
      })
    end
    warehouse_transaction_details
  end

  def self.get_concept_description concept_id
    case concept_id
    when ENTRY
      'Entrada'
    when RELOCATION
      'Reubicación'
    when WITHDRAW
      'Salida'
    end
  end

end
