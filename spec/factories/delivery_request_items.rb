FactoryGirl.define do
  factory :delivery_request_item do
    delivery_request
    inventory_item
    quantity 1
  end

end
