module ExtendedFactories
  module DeliveryHelpers
    def create_delivery_request(num_items)
      delivery_request = FactoryBot.create(:delivery_request)
      num_items.times do 
        item = FactoryBot.create(:inventory_item)
        item_atts = FactoryBot.attributes_for(:delivery_request_item)
        item_atts[:inventory_item_id] = item.id
        delivery_request.delivery_request_items << DeliveryRequestItem.create(item_atts)
      end

      delivery_request
    end

    def create_litobel_supplier
      supplier = FactoryBot.create :supplier
      supplier.update_attributes(name: 'Litobel')

      supplier
    end

    def create_random_suppliers(num_suppliers)
      num_suppliers.times { FactoryBot.create(:supplier, name: FFaker::Company.name) }
    end

    def create_delivery_with_user
      user = FactoryBot.create :user
      delivery = FactoryBot.create :delivery
      delivery.update_attributes(delivery_user_id: user.id)
      
      delivery
    end
  end
end