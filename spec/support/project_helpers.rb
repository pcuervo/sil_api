module ExtendedFactories
  module ProjectHelpers
    def create_project_with_items(num_items) 
      project = FactoryGirl.create(:project)
      supplier = FactoryGirl.create(:supplier)

      num_items.times do 
        item = FactoryGirl.create(:inventory_item, { project_id: project.id, quantity: 0 } )
        log_checkin_transaction(item.id, supplier.id, item.quantity)
      end
      project.reload

      project
    end

    def log_checkin_transaction(inventory_item_id, delivery_company, quantity)
      checkin_transaction = CheckInTransaction.new( :inventory_item_id => inventory_item_id, :concept => 'Entrada', :additional_comments => 'Testing!', :entry_date => Date.today, :estimated_issue_date => '', :delivery_company => delivery_company, :delivery_company_contact => 'Micho', :quantity => quantity, :folio => InventoryTransaction.next_checkin_folio)
      checkin_transaction.save!
    end  
	end
end