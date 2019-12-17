FactoryBot.define do
  factory :inventory_item_request do
    name                      { FFaker::Product.product_name }
    description               { FFaker::HipsterIpsum.phrase } 
    quantity                  { 10 }
    item_type                 { 'Laptop' }
    project_id                { 1 }
    ae_id                     { 4 }
    state                     { 1 }
    validity_expiration_date  { '2016-09-29' }
    entry_date                { '2016-09-29' }
  end

end
