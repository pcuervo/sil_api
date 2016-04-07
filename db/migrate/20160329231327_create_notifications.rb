class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string      :message
      t.integer     :inventory_item
      t.string      :status, default: 1
      t.timestamps  null: false
    end
  end
end
