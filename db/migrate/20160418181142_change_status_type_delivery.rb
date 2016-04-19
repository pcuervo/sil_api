class ChangeStatusTypeDelivery < ActiveRecord::Migration
  def change
    change_column :deliveries, :status, :integer, :default => 1
  end
end
