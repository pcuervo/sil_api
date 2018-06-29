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

  def authorize(pickup_company_contact, additional_comments, quantities = [])
    withdraw_request_items.each do |wri|
      wri.inventory_item.update_attributes(status: InventoryItem::IN_STOCK)
      quantity_to_withdraw = if quantities.empty?
                               wri.quantity.to_i
                             else
                               quantities[i].to_i
                             end
      withdrawn = wri.inventory_item.withdraw(exit_date, '', pickup_company_id, pickup_company_contact, additional_comments, quantity_to_withdraw)
      return false if withdrawn != true
    end
    destroy
    true
  end

  def cancel
    destroy
  end

  def remove_items
    withdraw_request_items.each(&:destroy)
  end
end
