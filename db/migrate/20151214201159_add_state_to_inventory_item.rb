class AddStateToInventoryItem < ActiveRecord::Migration
  def change
    add_column :inventory_items, :state, :int, default: 1
  end
end
