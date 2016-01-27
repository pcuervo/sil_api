class CreateInventoryItems < ActiveRecord::Migration
  def change
    create_table :inventory_items do |t|
      t.string      :name,        default: " "
      t.text        :description
      t.string      :image_url,   default: "default_item.png"
      t.integer      :status,      default: 1
      t.string      :item_type
      t.string      :barcode,     unique: true
      t.references  :user,        index: true
      t.references  :project,     index: true
      t.references  :client,      index: true
      t.integer     :actable_id
      t.string      :actable_type
      t.timestamps
    end
    add_foreign_key :inventory_items, :users
    add_foreign_key :inventory_items, :projects
    add_foreign_key :inventory_items, :clients
  end
end
