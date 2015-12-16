class CreateWarehouseLocations < ActiveRecord::Migration
  def change
    create_table :warehouse_locations do |t|
      t.string :name, default: ""
      t.integer :units, default: 1
      t.integer :status, default: 1
      t.references :warehouse_rack, index: true

      t.timestamps null: false
    end
    add_foreign_key :warehouse_locations, :warehouse_racks
  end
end
