class DeliveryRequestItems < ActiveRecord::Migration
  def change
    create_table :delivery_request_items do |t|
      t.references    :inventory_item,    index: true
      t.references    :delivery_request,  index: true
      t.integer       :quantity,          default: 1
      t.integer       :part_id,           default: 0

      t.timestamps null: false
    end
    add_foreign_key :delivery_request_items, :inventory_items
    add_foreign_key :delivery_request_items, :delivery_requests
  end
end
