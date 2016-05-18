FactoryGirl.define do
  factory :withdraw_request_item do
    withdraw_request
    inventory_item
    quantity 1
  end
end
