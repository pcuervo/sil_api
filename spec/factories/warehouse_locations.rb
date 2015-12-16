FactoryGirl.define do
  factory :warehouse_location do
    name { FFaker::AddressAU.country_code + FFaker::AddressAU.building_number }
    units 10
    status 1
    warehouse_rack
  end
end
