class WarehouseLocation < ActiveRecord::Base
  validates :name, presence: true
  validates :name, uniqueness: true
  belongs_to :warehouse_rack
  has_many :item_locations
  has_many :warehouse_transactions

  # Error codes
  IS_FULL = -1

  # Locates an InventoryItem in current WarehouseLocation
  # * *Params:* 
  #   - +inventory_item_id+ -> ID of InventoryItem to locate
  #   - +units+ -> Number of units the item occupies
  #   - +quantity+ -> Item quantity 
  #   - +part_id+ -> ID of BundleItemPart in case of partially moving a BundleItem
  # * *Returns:* 
  #   - ID of created ItemLocation
  def locate( inventory_item_id, units, quantity, part_id = 0 )
    return IS_FULL if get_available_units < units 

    inventory_item = InventoryItem.find( inventory_item_id )
    item_location = ItemLocation.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => units, :quantity => quantity )
    w = WarehouseTransaction.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => units, :quantity => quantity, :concept => WarehouseTransaction::ENTRY )

    puts 'status:'
    puts self.status.to_yaml
    item_location.save
    return item_location.id if part_id == 0

    item_location.part_id = part_id
    item_location.save
    return item_location.id
  end

  # Returns the available units in current WarehouseLocation
  # * *Returns:* 
  #   - number of available units
  def get_available_units
    return 0 if self.status == 3
    
    units = 0
    item_locations.each { |il| units += il.units }
    return self.units - units
  end

  def update_status
    available_units = get_available_units
    if 0 == available_units
      self.status = 3
    elsif available_units == self.units
      self.status = 1
    else
      self.status = 2
    end
    self.save
  end

end
