class CreateItemLocations < ActiveRecord::Migration
  def change
    create_table :item_locations do |t|
      t.references    :inventory_item, foreign_key: true
      t.references    :warehouse_location, foreign_key: true
      t.integer       :units, default: 1
      t.integer       :quantity, default: 1
      t.integer       :part_id, default: 0

      t.timestamps null: false
    end

  end
end
