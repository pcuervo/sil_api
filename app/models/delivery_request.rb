class DeliveryRequest < ActiveRecord::Base
  before_destroy :remove_items

  belongs_to  :user
  has_many    :delivery_request_items

  def update_items_status_to_pending
    delivery_request_items.each do |dri|
      inventory_item = dri.inventory_item

      inventory_item.status = InventoryItem::PENDING_DELIVERY
      inventory_item.save
    end
  end

  def authorize(delivery_user_id, supplier_id, additional_comments, _quantities = [])
    delivery = Delivery.create(company: company, address: address, latitude: latitude, longitude: longitude, status: Delivery::SHIPPED, addressee: addressee, addressee_phone: addressee_phone, date_time: date_time, delivery_user_id: delivery_user_id, supplier_id: supplier_id)
    user.deliveries << delivery

    items = []
    delivery_request_items.each do |dri|
      item = { item_id: dri.inventory_item.id, quantity: dri.quantity }
      items.push(item)
    end

    if delivery_user_id.to_i == -1
      delivery_user_name = 'Sin repartidor'
    else
      delivery_user = User.find(delivery_user_id)
      delivery_user_name = delivery_user.first_name + ' ' + delivery_user.last_name
    end

    delivery.add_items(items, delivery_user_name, additional_comments)

    destroy
  end

  def set_items_in_stock
    puts 'before setting status'
    delivery_request_items.each do |dri|
      dri.inventory_item.status = InventoryItem::IN_STOCK
      dri.inventory_item.save
      puts 'status: ' + dri.inventory_item.status.to_s
    end
  end

  def remove_items
    delivery_request_items.each(&:destroy)
  end
end
