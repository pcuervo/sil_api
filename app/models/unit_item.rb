class UnitItem < ActiveRecord::Base
  acts_as :inventory_item

  validates :serial_number, presence: true
  validates :serial_number, uniqueness: true

  # Withdraws UnitItem and remove from WarehouseLocation if it has any
  # * *Returns:* 
  #   - true if successful or error code
  def withdraw
    return self.status if cannot_withdraw?

    self.status = InventoryItem::OUT_OF_STOCK
    if self.save
      inventory_item = InventoryItem.find_by_actable_id( self.id )
      if self.has_location?
        item_location = self.item_locations.first
        location = item_location.warehouse_location
        location.remove_item( inventory_item.id )
      end
      return true
    end

    return false
  end

  def cannot_withdraw?
    case self.status
    when InventoryItem::OUT_OF_STOCK
      return true
    when InventoryItem::PENDING_ENTRY
      return true
    when InventoryItem::PENDING_WITHDRAWAL
      return true
    end
  end

end
