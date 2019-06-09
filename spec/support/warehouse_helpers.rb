module ExtendedFactories
  module WarehouseHelpers

    def locate_partially(warehouse_location, inventory_item, quantity) 
      item_location = ItemLocation.create(inventory_item_id: inventory_item.id, warehouse_location_id: warehouse_location.id, quantity: quantity)
      warehouse_location.item_locations << item_location

      WarehouseTransaction.create(inventory_item_id: inventory_item.id, warehouse_location_id: warehouse_location.id, quantity: quantity, concept: WarehouseTransaction::ENTRY)
    end

    def create_rack_with_locations(num_locations)
      rack = FactoryBot.create(:warehouse_rack)
      FactoryBot.create_list(:warehouse_location, num_locations, warehouse_rack_id: rack.id)

      rack
    end

    def create_location_with_items(num_items)
      rack = FactoryBot.create(:warehouse_rack)
      location = FactoryBot.create(:warehouse_location, warehouse_rack_id: rack.id)

      num_items.times do
        item = FactoryBot.create(:inventory_item)
        location.locate(item, item.quantity)
      end

      location
    end
  end
end