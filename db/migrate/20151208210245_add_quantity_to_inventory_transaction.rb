class AddQuantityToInventoryTransaction < ActiveRecord::Migration
  def change
    add_column :inventory_transactions, :quantity, :integer
  end
end
