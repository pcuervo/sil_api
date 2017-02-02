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

  def authorize delivery_user_id, supplier_id, additional_comments, quantities=[]

    delivery = Delivery.create( :company => self.company, :address => self.address, :latitude => self.latitude, :longitude => self.longitude, :status => Delivery::SHIPPED, :addressee => self.addressee, :addressee_phone => self.addressee_phone, :date_time => self.date_time, :delivery_user_id => delivery_user_id, :supplier_id => supplier_id )
    self.user.deliveries << delivery

    items = []
    self.delivery_request_items.each do |dri|
      item = {}
      item[:item_id] = dri.inventory_item.id
      item[:quantity] = dri.quantity
      items.push( item )
    end

    if -1 == delivery_user_id.to_i
      delivery_user_name = 'Sin repartidor'
    else
      delivery_user = User.find( delivery_user_id )
      delivery_user_name = delivery_user.first_name + ' ' + delivery_user.last_name
    end

    delivery.add_items( items, delivery_user_name, additional_comments )

    self.destroy

  end

  def set_items_in_stock
    puts 'before setting status'
    self.delivery_request_items.each do |dri|
      dri.inventory_item.status = InventoryItem::IN_STOCK
      dri.inventory_item.save
      puts 'status: ' + dri.inventory_item.status.to_s
    end
  end

  def remove_items
    self.delivery_request_items.each do |item|
      item.destroy
    end
  end
end
