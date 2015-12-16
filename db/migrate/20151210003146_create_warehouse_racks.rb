class CreateWarehouseRacks < ActiveRecord::Migration
  def change
    create_table :warehouse_racks do |t|
      t.string    :name, default: ""
      t.integer   :row, default: 1
      t.integer   :column, default: 1

      t.timestamps null: false
    end
  end
end
