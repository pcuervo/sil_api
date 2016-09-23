class DeliveryRequestItem < ActiveRecord::Base
  belongs_to  :delivery_request
  belongs_to  :inventory_item
end
