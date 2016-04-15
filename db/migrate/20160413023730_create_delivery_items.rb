class CreateDeliveryItems < ActiveRecord::Migration
  def change
    create_table :delivery_items do |t|
      t.references    :inventory_item,  index: true
      t.references    :delivery,        index: true
      t.integer       :quantity,        default: 1
      t.integer       :part_id,         default: 0

      t.timestamps null: false
    end
    add_foreign_key :item_locations, :inventory_items
    add_foreign_key :item_locations, :warehouse_locations
  end
end
