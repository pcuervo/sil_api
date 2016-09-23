FactoryGirl.define do
  factory :delivery_request do
    user
    company             { FFaker::Company.name }
    addressee           { FFaker::NameMX.full_name }
    addressee_phone     { FFaker::PhoneNumberMX.phone_number }
    address             { FFaker::Address.street_address + ', ' + FFaker::Address.city }
    latitude            '19.401893'
    longitude           '-99.172152'
    additional_comments { FFaker::HipsterIpsum.phrase }
    date_time           Time.now
  end
end
