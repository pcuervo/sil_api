class BundleItemPart < ActiveRecord::Base
  belongs_to :bundle_item

  validates :name, presence: true

  def get_details
    locations = warehouse_locations
    details = {
      'id'              => self.id,
      'name'            => self.name,
      'brand'           => self.brand,
      'model'           => self.model,
      'serial_number'   => self.serial_number,
      'status'          => self.status,
      'locations'       => locations,
      'created_at'      => self.created_at
    }
    details
  end

  def warehouse_locations
    locations = []
    item_locations = ItemLocation.where( 'part_id = ?', self.id )

    if item_locations.empty?
      bundle_item = BundleItem.find( self.bundle_item_id )
      return bundle_item.warehouse_locations
    end

    item_locations.each do |il|
      locations.push({
        'location_id' => il.warehouse_location.id,
        'location'    => il.warehouse_location.name + ' - ' + il.units.to_s,
        'quantity'    => il.quantity,
        'units'       => il.units
      })
    end
    locations
  end

end
