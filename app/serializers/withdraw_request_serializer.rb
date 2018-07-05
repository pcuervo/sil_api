class WithdrawRequestSerializer < ActiveModel::Serializer
  attributes :id, :exit_date, :pickup_company_id, :user, :withdraw_request_items, :pickup_company

  def withdraw_request_items
    withdraw_request_items = []
    object.withdraw_request_items.each do |wri|
      withdraw_request_item = {}
      withdraw_request_item[:quantity] = wri.quantity
      withdraw_request_item[:name] = wri.inventory_item.name
      withdraw_request_item[:item_type] = wri.inventory_item.item_type
      withdraw_request_item[:item_img] = wri.inventory_item.item_img(:thumb)
      withdraw_request_item[:actable_type] = wri.inventory_item.actable_type
      withdraw_request_items.push( withdraw_request_item )
    end
    withdraw_request_items
  end

  def pickup_company
    supplier = Supplier.find_by_id( object.pickup_company_id )
    return '-' if ! supplier.present?

    supplier.name
  end
end
