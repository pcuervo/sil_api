FactoryGirl.define do
  factory :inventory_item do
    name { FFaker::Product.product_name }
    description { FFaker::HipsterIpsum.paragraph } 
    item_type "Desktop"
    user
    project
    value 100.00
    barcode { FFaker::Vehicle.vin }
  end
end
