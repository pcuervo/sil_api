FactoryGirl.define do
  factory :inventory_item do
    name { FFaker::Product.product_name }
    description { FFaker::HipsterIpsum.paragraph } 
    item_type "Desktop"
    user
    project
    barcode { FFaker::Vehicle.vin }
  end
end
