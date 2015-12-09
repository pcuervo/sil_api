class ChangeDefaultStatusToInventoryItems < ActiveRecord::Migration
  def change
    change_table :inventory_items do |t|
      change_column :inventory_items, :status, :integer, :default => 1
    end
  end
end
