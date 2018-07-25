module ExtendedFactories
  module ItemHelpers
    # Used to test search. Create Items that
    # start with similar serial number.
    def create_items_for_quick_search(sn_prefix, num_items) 
      num_items.times { |i| FactoryGirl.create(:inventory_item, serial_number: sn_prefix + i.to_s) }
    end
	end
end