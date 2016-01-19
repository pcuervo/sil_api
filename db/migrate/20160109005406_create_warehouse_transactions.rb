class CreateWarehouseTransactions < ActiveRecord::Migration
  def change
    create_table :warehouse_transactions do |t|
      t.references  :inventory_item, index: true
      t.references  :warehouse_location, index: true
      t.integer     :concept, default: 1
      t.integer     :units, default: 1
      t.integer     :quantity, default: 1
      t.integer     :part_id, default: 0

      t.timestamps null: false
    end
    add_foreign_key :warehouse_transactions, :inventory_items
    add_foreign_key :warehouse_transactions, :warehouse_locations
  end
end
