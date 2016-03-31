class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string      :message
      t.references  :inventory_item, index: true
      t.string      :status, default: 1
      t.timestamps  null: false
    end
    add_foreign_key :notifications, :inventory_items
  end
end
