FactoryBot.define do
  factory :bulk_item do
    name { FFaker::Product.product_name }
    description { FFaker::HipsterIpsum.paragraph }
    user
    project
    barcode { FFaker::Vehicle.vin }
    quantity { 100 }
    item_type { 'POP' }
    state { 1 }
    value { 100 }
  end

end
