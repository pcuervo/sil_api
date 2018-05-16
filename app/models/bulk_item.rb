class BulkItem < ActiveRecord::Base
  acts_as :inventory_item

  # Withdraws BulkItem and remove from WarehouseLocation if it has any
  # * *Returns:* 
  #   - true if successful or error code
  def withdraw exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments, quantity, folio
    
    return self.status if cannot_withdraw?

    if quantity != '' and quantity < self.quantity.to_i
      self.quantity = self.quantity.to_i - quantity
      quantity_withdrawn = quantity
    else
      self.status = InventoryItem::OUT_OF_STOCK
      quantity_withdrawn = self.quantity
      self.quantity = 0
    end
    
    if self.save
      inventory_item = InventoryItem.where( 'actable_id = ? AND actable_type = ?', self.id, 'BulkItem' ).first
      if self.has_location?
        quantity_left = quantity
        if quantity != '' and quantity < ( self.quantity.to_i + quantity_withdrawn.to_i )
          item_location = self.item_locations.where( 'quantity >= ?', quantity ).first
          location = item_location.warehouse_location
          location.remove_quantity( inventory_item.id, quantity, 1 )
        elsif quantity != ''
          while quantity_left > 0
            item_location = self.item_locations.first
            location = item_location.warehouse_location
            if quantity_left >= item_location.quantity 
              current_location_quantity = item_location.quantity 
              location.remove_item( inventory_item.id )
              self.item_locations.delete( item_location )
              location.update_status
            else
              location.remove_quantity( inventory_item.id, quantity_left, 1 )
            end
            quantity_left = quantity_left - current_location_quantity
          end
        else
          item_location = self.item_locations.first
          location = item_location.warehouse_location
          location.remove_item( inventory_item.id )
          self.item_locations.delete( item_location )
          location.update_status
        end
      end
      CheckOutTransaction.create( :inventory_item_id => inventory_item.id, :concept => 'Salida granel', :additional_comments => additional_comments, :exit_date => exit_date, :estimated_return_date => estimated_return_date, :pickup_company => pickup_company, :pickup_company_contact => pickup_company_contact, :quantity => quantity_withdrawn, :folio => folio )
      return true
    end

    return false
  end

end
