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
      supplier = FactoryBot.create(:supplier)

      item.add(quantity, InventoryItem::NEW, Date.today, 'Entrada inicial', supplier.id, 'NA', 'Alta de inventario de un wey tops', InventoryTransaction.next_checkin_folio)
      location.locate(item, quantity)

      item
    end
  end
end