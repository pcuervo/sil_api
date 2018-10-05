class ItemLocation < ActiveRecord::Base
  belongs_to :inventory_item
  belongs_to :warehouse_location
  after_destroy :update_location

  def update_location
    puts 'we updating location'
    location = WarehouseLocation.find(warehouse_location_id)
    location.update_status
  end

  def details
    location = warehouse_location
    details = { 'item_location' => {
      'id' => id,
      'item_id' => inventory_item.id,
      'location_id' => location.id,
      'item' => inventory_item.name,
      'quantity' => quantity,
      'item_img' => inventory_item.item_img(:medium),
      'barcode' => inventory_item.barcode,
      'location' => location.name,
      'rack_id' => location.warehouse_rack.id,
      'rack_name' => location.warehouse_rack.name,
      'available_units' => location.available_units
    } }

    details
  end
end
