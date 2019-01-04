module ExtendedFactories
  module ItemHelpers
    # Used to test search. Create Items that
    # start with similar serial number.
    def create_items_for_quick_search(sn_prefix, num_items) 
      num_items.times { |i| FactoryBot.create(:inventory_item, serial_number: sn_prefix + i.to_s) }
    end

    def create_item_with_location(quantity, project)
      item = FactoryBot.create(:inventory_item, quantity: 0, project_id: project.id)
      location = FactoryBot.create(:warehouse_location)
      supplier = Supplier.find_or_create_by(name: 'Litobel')

      item.add(quantity, InventoryItem::NEW, Date.today, 'Entrada inicial', supplier.id, 'NA', 'Alta de inventario de un wey tops', InventoryTransaction.next_checkin_folio)
      location.locate(item, quantity)

      item
    end

    # Used to simulate CSV data to replenish Inventory
    def format_for_replenish(items, quantity, location)
      item_data = []
      items.each do |item|
        data = []
        data.push(item.id)
        data.push(item.name)
        data.push(quantity)
        data.push(location.name)
        data.push(FFaker::HipsterIpsum.sentence)
        item_data.push(data)
      end
      item_data
    end

  end
end