class RemoveFieldsFromItemLocations < ActiveRecord::Migration
  def change
    remove_column :item_locations, :part_id
    remove_column :item_locations, :units
  end
end
