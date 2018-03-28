class AddNewFieldsInventoryItem < ActiveRecord::Migration
  def change
    add_column :inventory_items, :quantity, :integer, default: 0
    add_column :inventory_items, :serial_number, :string, default: ' '
    add_column :inventory_items, :brand, :string, default: ' '
    add_column :inventory_items, :model, :string, default: ' '
  end
end
