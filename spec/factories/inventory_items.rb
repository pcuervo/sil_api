FactoryGirl.define do
  factory :inventory_item do
    name { FFaker::Product.product_name }
    description { FFaker::HipsterIpsum.paragraph } 
    item_type "Desktop"
    user
    project
    value 100.00 
    sequence(:barcode){|n| Random.rand(100).to_s + n.to_s + FFaker::Vehicle.vin + Random.rand(10000).to_s }
  end
end
