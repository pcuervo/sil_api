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

  def authorize pickup_company_contact, additional_comments
    withdraw_request_items.each do |wri|
      inventory_item = wri.inventory_item
      wri.inventory_item.status = InventoryItem::IN_STOCK
      withdrawn = inventory_item.withdraw( self.exit_date, '', self.pickup_company_id, pickup_company_contact, additional_comments, wri.quantity.to_i )
      if withdrawn != true
        return false
      end
    end
    self.destroy
    return true
  end

  def remove_items
    self.withdraw_request_items.each do |item|
      item.destroy
    end
  end
end
