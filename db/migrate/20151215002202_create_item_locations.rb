class CreateItemLocations < ActiveRecord::Migration
  def change
    create_table :item_locations do |t|
      t.references    :inventory_item, index: true
      t.references    :warehouse_location, index: true
      t.integer       :units, default: 1
      t.integer       :quantity, default: 1
      t.integer       :part_id, default: 0

      t.timestamps null: false
    end
    add_foreign_key :item_locations, :inventory_items
    add_foreign_key :item_locations, :warehouse_locations
  end
end
