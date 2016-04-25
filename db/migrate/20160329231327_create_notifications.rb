class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string      :message
      t.integer     :inventory_item_id
      t.integer     :status, default: 1
      t.timestamps  null: false
    end
  end
end
