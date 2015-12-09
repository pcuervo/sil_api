FactoryGirl.define do
  factory :bundle_item_part do
    name { FFaker::Product.product_name }
    serial_number { FFaker::IdentificationMX.curp }
    brand { FFaker::Product.brand }
    model { FFaker::Product.model }
    bundle_item
  end
end
