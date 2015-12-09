FactoryGirl.define do
  factory :check_in_transaction do
    inventory_item
    concept "Entrada unitaria"
    additional_comments { FFaker::HipsterIpsum.paragraph }
    entry_date { FFaker::Time.date }
    estimated_issue_date { FFaker::Time.date }
    delivery_company { FFaker::Product.brand }
    delivery_company_contact { FFaker::PhoneNumber.phone_number }
  end
end
