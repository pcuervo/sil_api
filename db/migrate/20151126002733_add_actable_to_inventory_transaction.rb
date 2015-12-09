class AddActableToInventoryTransaction < ActiveRecord::Migration
  def change
    change_table :inventory_transactions do |t| 
      t.actable
    end
  end
end
