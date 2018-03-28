FactoryGirl.define do
  factory :inventory_item do
    name { FFaker::Product.product_name }
    description { FFaker::HipsterIpsum.paragraph } 
    item_type "Desktop"
    user
    project
    value 100.00
    serial_number { FFaker::Vehicle.vin }
    quantity 100
    brand 'Marquis'
    model 'Modes'
    barcode { FFaker::Vehicle.vin }
  end
end
