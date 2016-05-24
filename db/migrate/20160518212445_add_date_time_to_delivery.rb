class AddDateTimeToDelivery < ActiveRecord::Migration
  def change
    add_column :deliveries, :date_time, :datetime
  end
end
