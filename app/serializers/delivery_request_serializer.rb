class DeliveryRequestSerializer < ActiveModel::Serializer
  attributes :id, :company, :addressee, :addressee_phone, :address, :latitude, :longitude, :additional_comments, :delivery_request_items, :date_time, :user

  def delivery_request_items
    items = []
    object.delivery_request_items.each do |i|
      item = {}
      item[:name] = i.inventory_item.name
      item[:quantity] = i.quantity
      item[:item_type] = i.inventory_item.item_type
      items.push( item )
    end
    items
  end
end


