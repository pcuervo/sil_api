FactoryGirl.define do
  factory :notification do
    title { 'Entrada Pendiente' }
    message { FFaker::HipsterIpsum.phrase } 
    inventory_item_id 1
  end
end
