class DeliveryItem < ActiveRecord::Base
  belongs_to :delivery


  def self.details
    delivery_items = DeliveryItem.all

    delivery_items_details = []
    delivery_items.each do |di|
      inventory_item = InventoryItem.find( di.inventory_item_id )
      delivery_items_details.push({
        'id'                        => di.id,
        'name'                      => inventory_item.name,
        'item_type'                 => inventory_item.item_type,
        'quantity'                  => di.quantity,
        'created_at'                => di.created_at
      })
    end

    delivery_items_details
  end
end
