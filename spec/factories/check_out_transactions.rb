FactoryBot.define do
  factory :check_out_transaction do
    inventory_item
    concept { "Salida" }
    additional_comments { FFaker::HipsterIpsum.paragraph }
    exit_date { FFaker::Time.date }
    estimated_return_date { FFaker::Time.date }
    pickup_company { FFaker::Product.brand }
    pickup_company_contact { FFaker::PhoneNumber.phone_number }
    folio { InventoryTransaction.next_checkout_folio }
  end
end
