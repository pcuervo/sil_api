FactoryBot.define do
  factory :delivery do
    user
    delivery_user_id    { 2 }
    company             { FFaker::CompanyIT.name + Time.now.getutc.to_s }
    addressee           { FFaker::NameMX.full_name }
    addressee_phone     { FFaker::PhoneNumberMX.phone_number }
    address             { FFaker::Address.street_address + ', ' + FFaker::Address.city }
    latitude            { '19.401893' }
    longitude           { '-99.172152' }
    status              { 1 }
    additional_comments { FFaker::HipsterIpsum.phrase }
    date_time { Time.now }
  end
end
