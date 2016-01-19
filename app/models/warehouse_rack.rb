class WarehouseRack < ActiveRecord::Base
  validates :name, uniqueness: true
  has_many :warehouse_locations

  def available_locations
    available_locations_info = { 'available_locations' => [] }
    self.warehouse_locations.each do |location|
      if location.get_available_units > 0
        available_locations_info['available_locations'].push({
          'id'              => location.id,
          'name'            => location.name,
          'units'           => location.units,
          'available_units' => location.get_available_units,
          'status'          => location.status
        })
      end 
    end
    return available_locations_info
  end
end
