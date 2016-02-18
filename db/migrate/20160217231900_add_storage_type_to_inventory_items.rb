class AddStorageTypeToInventoryItems < ActiveRecord::Migration
  def change
    add_column :inventory_items, :storage_type, :string
  end
end
