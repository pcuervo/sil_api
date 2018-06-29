module ExtendedFactories
  module DeliveryHelpers
    def create_delivery_request(num_items)
      delivery_request = FactoryGirl.create(:delivery_request)
      num_items.times do 
        item = FactoryGirl.create(:inventory_item)
        item_atts = FactoryGirl.attributes_for(:delivery_request_item)
        item_atts[:inventory_item_id] = item.id
        delivery_request.delivery_request_items << DeliveryRequestItem.create(item_atts)
      end

      delivery_request
    end

    def create_litobel_supplier
      supplier = FactoryGirl.create :supplier
      supplier.update_attributes(name: 'Litobel')

      supplier
    end
  end
end