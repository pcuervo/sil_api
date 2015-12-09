FactoryGirl.define do
  factory :inventory_transaction do
    inventory_item
    concept "Entrada unitaria"
    additional_comments { FFaker::HipsterIpsum.paragraph }
  end

end
