FactoryGirl.define do
  factory :client_contact do
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    phone { FFaker::PhoneNumberMX.phone_number }
    phone_ext { 123 }
    email { FFaker::Internet.email }
    business_unit { FFaker::Company.position }
    client 
    role 6
    password "holama123"
    password_confirmation "holama123"
  end

end
