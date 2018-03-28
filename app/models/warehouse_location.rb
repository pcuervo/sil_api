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
  ITEM_ALREADY_LOCATED = -4

  # Locates an InventoryItem in current WarehouseLocation
  # * *Params:* 
  #   - +inventory_item_id+ -> ID of InventoryItem to locate
  #   - +units+ -> Number of units the item occupies
  #   - +quantity+ -> Item quantity 
  #   - +part_id+ -> ID of BundleItemPart in case of partially moving a BundleItem
  # * *Returns:* 
  #   - ID of created ItemLocation
  def locate( inventory_item_id, units, quantity, part_id = 0 )

    item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item_id, self.id ).first
    if item_location.present?

      inventory_item = item_location.inventory_item 
      if( 'BulkItem' == inventory_item.actable_type )
        bulk_item = BulkItem.find( inventory_item.actable_id )
        return ITEM_ALREADY_LOCATED if ( item_location.quantity + quantity ) > bulk_item.quantity

        item_location.quantity = item_location.quantity + quantity
        item_location.units = item_location.quantity
        if item_location.quantity > bulk_item.quantity 
          item_location.quantity = bulk_item.quantity 
        end
      end

      item_location.save
      w = WarehouseTransaction.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => item_location.quantity, :quantity => item_location.quantity, :concept => WarehouseTransaction::ENTRY )
    else
      inventory_item = InventoryItem.find( inventory_item_id )
      if( 'BulkItem' == inventory_item.actable_type )
        bulk_item = BulkItem.find( inventory_item.actable_id )
        if quantity > bulk_item.quantity 
          quantity = bulk_item.quantity 
        end
      end

      item_location = ItemLocation.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => quantity, :quantity => quantity )
      self.item_locations << item_location
      w = WarehouseTransaction.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => quantity, :quantity => quantity, :concept => WarehouseTransaction::ENTRY )
    end

    self.update_status
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
    item_location = self.item_locations.find_by_inventory_item_id( inventory_item_id )
  
    w = WarehouseTransaction.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => item_location.quantity, :quantity => item_location.quantity, :concept => WarehouseTransaction::WITHDRAW )
    self.item_locations.delete( item_location )
    item_location.destroy
    return item_location.present?
  end

  # Remove a quantity of an item from current location. By default
  # the concept is WITHDRAWAL (3).
  # * *Params:* 
  #   - +inventory_item_id+ -> ID of ItemLocation to relocate
  #   - +quantity+ -> quantity to remove
  # * *Returns:* 
  #   - current quantity or error
  def remove_quantity( inventory_item_id, quantity, units, concept=3 )

    item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item_id, self.id ).first
    
    return NOT_ENOUGH_STOCKS if quantity > item_location.quantity 
    #return NOT_ENOUGH_UNITS if units > item_location.units 

    item_location.quantity -= quantity
    item_location.units -= units
    if item_location.units <= 0 && item_location.quantity > 0
      item_location.units = item_location.quantity
    elsif item_location.units <= 0 
      item_location.units = 0
    end

    item_location.save
    w = WarehouseTransaction.create( :inventory_item_id => inventory_item_id, :warehouse_location_id => self.id, :units => units, :quantity => quantity, :concept => concept )

    if item_location.quantity == 0 
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
    return 999
    # units = 0
    # self.item_locations.each { |il| units += il.units }
    # return self.units - units
  end

  def update_status
    return if self.status == NO_SPACE

    if self.item_locations.count == 0
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

  def empty
    self.item_locations.each do |item_location|  
      quantity_to_remove = item_location.quantity
      self.remove_quantity(item_location.inventory_item_id, quantity_to_remove, quantity_to_remove, WarehouseTransaction::EMPTIED)
    end

    true
  end

  def mark_as_full
    puts 'marking as full...'
    self.status = NO_SPACE
    puts self.status.to_yaml
    self.save
  end

  def mark_as_available
    if self.item_locations.count == 0
      self.status = EMPTY
    else
      self.status = PARTIAL_SPACE
    end
    self.save
  end

end
