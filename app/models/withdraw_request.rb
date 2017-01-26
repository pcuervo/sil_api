class WithdrawRequest < ActiveRecord::Base
  before_destroy :remove_items

  belongs_to  :user
  has_many    :withdraw_request_items

  def update_items_status_to_pending
    withdraw_request_items.each do |wri|
      inventory_item = wri.inventory_item
      inventory_item.status = InventoryItem::PENDING_WITHDRAWAL
      inventory_item.save
    end
  end

  def authorize pickup_company_contact, additional_comments, quantities=[]
    withdraw_request_items.each_with_index do |wri, i|
      inventory_item = wri.inventory_item
      wri.inventory_item.status = InventoryItem::IN_STOCK
      wri.inventory_item.save
      if quantities.empty?
        quantity_to_withdraw = wri.quantity.to_i
      else
        quantity_to_withdraw = quantities[i].to_i
      end
      withdrawn = inventory_item.withdraw( self.exit_date, '', self.pickup_company_id, pickup_company_contact, additional_comments, quantity_to_withdraw )
      if withdrawn != true
        return false
      end
    end
    self.destroy
    return true
  end

  def cancel
    return self.destroy
  end

  def remove_items
    self.withdraw_request_items.each do |item|
      item.destroy
    end
  end
end
