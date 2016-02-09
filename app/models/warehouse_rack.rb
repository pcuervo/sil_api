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

  def details
    rack_info = { 'rack_info' => { :rows => self.row, :columns => self.column }, 'locations' => [] }
    self.warehouse_locations.each do |location|
      rack_info['locations'].push({
        'id'              => location.id,
        'name'            => location.name,
        'units'           => location.units,
        'available_units' => location.get_available_units,
        'status'          => location.status
      })
    end
    return rack_info
  end

  def add_initial_locations units
    row.times do |r|
      column.times do |c|
        location_name = name + '-' + ( r + 1 ).to_s + '-' + ( c + 1 ).to_s
        new_location = WarehouseLocation.create( :name => location_name, :units => units )
        warehouse_locations << new_location
      end
    end
  end
  
end
