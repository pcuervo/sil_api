class AddSupplierIdToDeliveries < ActiveRecord::Migration
  def change
    add_column :deliveries, :supplier_id, :integer
  end
end
