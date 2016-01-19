FactoryGirl.define do
  factory :warehouse_transaction do
    inventory_item  
    warehouse_location
    concept 1
    units 1
    quantity 1
    part_id 0
  end
end
