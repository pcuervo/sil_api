class AddDateTimeToDeliveryRequest < ActiveRecord::Migration
  def change
    add_column :delivery_requests, :date_time, :datetime
  end
end
