class UnitItem < ActiveRecord::Base
  acts_as :inventory_item

  #validates :serial_number, uniqueness: true

  # Withdraws UnitItem and remove from WarehouseLocation if it has any
  # * *Returns:* 
  #   - true if successful or error code
  def withdraw exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments
    return self.status if cannot_withdraw?

    self.status = InventoryItem::OUT_OF_STOCK
    if self.save
      inventory_item = InventoryItem.find_by_actable_id( self.id )
      if self.has_location?
        item_location = self.item_locations.first
        location = item_location.warehouse_location
        location.remove_item( inventory_item.id )
      end
      CheckOutTransaction.create( :inventory_item_id => inventory_item.id, :concept => 'Salida unitaria', :additional_comments => additional_comments, :exit_date => exit_date, :estimated_return_date => estimated_return_date, :pickup_company => pickup_company, :pickup_company_contact => pickup_company_contact, :quantity => 1 )
      return true
    end

    return false
  end

end
