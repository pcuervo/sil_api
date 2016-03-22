FactoryGirl.define do
  factory :item_location do
    inventory_item
    warehouse_location
    units 10
    quantity 1
    part_id 0
  end

end
