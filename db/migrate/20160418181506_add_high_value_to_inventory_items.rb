class AddHighValueToInventoryItems < ActiveRecord::Migration
  def change
    add_column :inventory_items, :is_high_value, :integer, :default => 0
  end
end
