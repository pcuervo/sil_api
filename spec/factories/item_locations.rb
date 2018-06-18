FactoryGirl.define do
  factory :item_location do
    inventory_item
    warehouse_location
    quantity 1
  end

end
