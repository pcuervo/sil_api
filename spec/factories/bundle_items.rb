FactoryGirl.define do
  factory :bundle_item do
    name { FFaker::Product.product_name + '_' + FFaker::Product.model }
    description { FFaker::HipsterIpsum.paragraph }
    user
    project
    barcode { FFaker::Vehicle.vin }
    item_type 'POP'
    is_complete true
    num_parts 0
    state 1
    value 110
  end

end
