class ItemLocation < ActiveRecord::Base
  belongs_to :inventory_item
  belongs_to :warehouse_location
  after_destroy :update_location

  def update_location
    location = WarehouseLocation.find( self.warehouse_location_id )
    location.update_status
  end

  def get_details
    item = self.inventory_item
    location = self.warehouse_location
    details = { 'item_location' => {
        'id'              => self.id,
        'item_id'         => item.id,
        'location_id'     => location.id,
        'units'           => self.units,
        'item'            => item.name,
        'item_img'        => item.item_img(:medium),
        'barcode'         => item.barcode,
        'location'        => location.name,
        'rack_id'         => location.warehouse_rack.id,
        'rack_name'       => location.warehouse_rack.name,
        'available_units' => location.get_available_units
      }  
    }

    if self.part_id != 0
      part = BundleItemPart.find( self.part_id )
      details['item_location']['part_id'] = part.id
      details['item_location']['part_name'] = part.name
    end
    details
  end
end