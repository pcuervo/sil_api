class WarehouseLocation < ActiveRecord::Base
  validates :name, presence: true
  validates :name, uniqueness: true
  validates :units, numericality: { only_intenger: true, greater_than: 0 }
  belongs_to :warehouse_rack
  has_many :item_locations
  has_many :warehouse_transactions

  # Status
  EMPTY = 1
  PARTIAL_SPACE = 2
  NO_SPACE = 3

  # Error codes
  IS_FULL = -1
  NOT_ENOUGH_STOCKS = -2
  NOT_ENOUGH_UNITS = -3

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

    item_location.save
    return item_location.id if part_id == 0

    item_location.part_id = part_id
    item_location.save
    return item_location.id
  end

  # Relocates an existing InventoryItem to current WarehouseLocation
  # * *Params:* 
  #   - +item_location_id+ -> ID of ItemLocation to relocate
  #   - +units+ -> Units to relocate
  #   - +quantity+ -> Item quantity 
  #   - +part_id+ -> ID of BundleItemPart in case of relocating a BundleItem
  # * *Returns:* 
  #   - ID of new ItemLocation
  def relocate( item_location_id, units, quantity, part_id = 0 )
    return IS_FULL if get_available_units < units 

    item_location = ItemLocation.find( item_location_id )
    inventory_item = InventoryItem.find( item_location.inventory_item_id )
    old_location = item_location.warehouse_location
    new_item_location = ItemLocation.create( :inventory_item_id => item_location.inventory_item_id, :warehouse_location_id => self.id, :units => item_location.units, :quantity => quantity )
    w = WarehouseTransaction.create( :inventory_item_id => item_location.inventory_item_id, :warehouse_location_id => self.id, :units => item_location.units, :quantity => quantity, :concept => WarehouseTransaction::RELOCATION )

    new_item_location.save
    item_location.destroy

    return new_item_location.id if part_id == 0

    new_item_location.part_id = part_id
    new_item_location.save
    return new_item_location.id
  end

  # Remove an item from current location
  # * *Params:* 
  #   - +inventory_item_id+ -> ID of ItemLocation to relocate
  # * *Returns:* 
  #   - bool if item was removed successfully
  def remove_item( inventory_item_id )
    item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item_id, self.id ).first
    w = WarehouseTransaction.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => item_location.units, :quantity => item_location.quantity, :concept => WarehouseTransaction::WITHDRAW )
    item_location.destroy
    return item_location.present?
  end

  # Remove a quantity of an item from current location
  # * *Params:* 
  #   - +inventory_item_id+ -> ID of ItemLocation to relocate
  #   - +quantity+ -> quantity to remove
  # * *Returns:* 
  #   - current quantity or error
  def remove_quantity( inventory_item_id, quantity, units )

    item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item_id, self.id ).first
    
    return NOT_ENOUGH_STOCKS if quantity > item_location.quantity 
    return NOT_ENOUGH_UNITS if units > item_location.units 

    item_location.quantity -= quantity
    item_location.units -= units
    item_location.save
    w = WarehouseTransaction.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => units, :quantity => quantity, :concept => WarehouseTransaction::WITHDRAW )

    if item_location.quantity == 0 or item_location.units == 0
      item_location.destroy
      return 0
    end
    self.update_status
    return item_location.quantity
  end

  # Returns the available units in current WarehouseLocation
  # * *Returns:* 
  #   - number of available units
  def get_available_units
    return 0 if self.status == NO_SPACE
    
    units = 0
    item_locations.each { |il| units += il.units }
    return self.units - units
  end

  def update_status
    available_units = get_available_units
    if 0 == available_units
      self.status = NO_SPACE
    elsif available_units == self.units
      self.status = EMPTY
    else
      self.status = PARTIAL_SPACE
    end
    self.save
  end

  def get_details
    inventory_items = []
    self.item_locations.each { |il| inventory_items.push( il.inventory_item.get_details ) }
    details = { 'warehouse_location' => {
        'id'                        => self.id,
        'name'                      => self.name,
        'status'                    => self.status,
        'units'                     => self.units,
        'warehouse_rack'            => self.warehouse_rack,
        'item_locations'            => self.item_locations,
        'inventory_items'           => inventory_items,
      }  
    }
  end

end
