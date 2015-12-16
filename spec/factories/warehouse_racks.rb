FactoryGirl.define do
  factory :warehouse_rack do
    name { FFaker::AddressAU.country_code + FFaker::AddressAU.building_number }
    row 10
    column 10
  end

end
