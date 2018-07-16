module ExtendedFactories
  module ProjectHelpers
    def create_project_with_items(num_items) 
      project = FactoryGirl.create(:project)

      num_items.times { FactoryGirl.create(:inventory_item, project_id: project.id) }
      project.reload

      project
    end
	end
end