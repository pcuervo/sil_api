class RemoveStorageTypeFromInventoryTransactions < ActiveRecord::Migration
  def change
    remove_column :inventory_transactions, :storage_type
  end
end
