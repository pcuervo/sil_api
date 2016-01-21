class AddValueToInventoryItems < ActiveRecord::Migration
  def change
    add_column :inventory_items, :value, :decimal, :default => 0.0, :precision => 10, :scale => 2, :after => :project_id
  end
end
