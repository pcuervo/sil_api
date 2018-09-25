FactoryBot.define do
  factory :warehouse_rack do
    name { FFaker::AddressAU.country_code + FFaker::AddressAU.building_number }
    row { 8 }
    column { 5 }
  end

end
