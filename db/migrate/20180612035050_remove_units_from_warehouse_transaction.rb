class RemoveUnitsFromWarehouseTransaction < ActiveRecord::Migration
  def change
    remove_column :warehouse_transactions, :units
  end
end
