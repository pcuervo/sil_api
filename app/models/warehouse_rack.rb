class WarehouseRack < ActiveRecord::Base
  validates :name, uniqueness: true
  has_many :warehouse_locations

  def available_locations
    available_locations_info = { 'available_locations' => [] }
    warehouse_locations.order(:name).each do |location|
      next unless location.available_units > 0

      available_locations_info['available_locations'].push(
        'id' => location.id,
        'name'            => location.name,
        'units'           => location.units,
        'available_units' => location.available_units,
        'status'          => location.status
      )
    end
    available_locations_info
  end

  def self.more_info
    racks_details = { 'warehouse_racks' => [] }
    WarehouseRack.all.each do |r|
      racks_details['warehouse_racks'].push(
        'id' => r.id,
        'name'                => r.name,
        'row'                 => r.row,
        'column'              => r.column,
        'total_locations'     => r.warehouse_locations.count,
        'available_locations' => r.available_locations['available_locations'].count,
        'is_empty'            => r.empty?,
        'created_at'          => r.created_at
      )
    end
    racks_details
  end

  def details
    rack_info = {
      'rack_info' => { rows: row, columns: column, name: name },
      'locations' => []
    }
    warehouse_locations.order(:id).each do |location|
      rack_info['locations'].push(
        'id' => location.id,
        'name'            => location.name,
        'units'           => location.units,
        'available_units' => location.available_units,
        'status'          => location.status
      )
    end
    rack_info
  end

  def add_initial_locations(units)
    row_letters = %w[A B C D E F G H I J K L]
    # row_letters = row_letters.reverse
    row.downto(1) do |r|
      column.times do |c|
        location_name = name + '-' + row_letters[r - 1] + '-' + (c + 1).to_s
        new_location = WarehouseLocation.create(name: location_name, units: units)
        warehouse_locations << new_location
      end
    end
  end

  def items
    rack_items = { 'items' => [] }
    warehouse_locations.order(updated_at: :desc).each do |l|
      l.item_locations.order(created_at: :desc).each do |il|
        unless il.inventory_item.present?
          il.destroy
          next
        end

        item = il.inventory_item
        rack_items['items'].push(
          'id' => item.id,
          'img'           => item.item_img(:medium),
          'thumb'         => item.item_img(:thumb),
          'name'          => item.name,
          'brand'         => item.brand,
          'project_name'  => item.project.name,
          'location_id'   => il.warehouse_location_id,
          'location'      => il.warehouse_location.name,
          'quantity'      => il.quantity,
          'created_at'    => il.created_at,
          'item_type'     => item.item_type,
          'actable_type'  => item.actable_type,
          'serial_number' => item.serial_number
        )
      end
    end
    rack_items
  end

  def empty?
    warehouse_locations.each do |location|
      return false if location.item_locations.count > 0
      # return false if location.available_units < location.units
    end
    true
  end

  def update_locations
    warehouse_locations.each(&:update_status)
  end

  def empty
    warehouse_locations.each(&:empty)

    true
  end
end
