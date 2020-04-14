FactoryBot.define do
  factory :inventory_item do
    sequence(:name) { |n| rand(100).to_s + FFaker::Product.product_name + n.to_s + rand(100).to_s }
    description { FFaker::HipsterIpsum.paragraph } 
    item_type { "Desktop" }
    user
    project
    state InventoryItem::NEW
    value { 100.00 }
    serial_number { FFaker::Vehicle.vin }
    quantity { 100 }
    brand { 'Marquis' }
    model { 'Modes' }
    sequence(:barcode) { |n| FFaker::Vehicle.vin + n.to_s + rand(100).to_s }
  end
end
