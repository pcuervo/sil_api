FactoryBot.define do
  sequence(:email) { |n| FFaker::Internet.email.downcase + n.to_s }

  factory :user do
  	first_name { "Juan" }
  	last_name { "Camaney" }
    email
    password { "holama123" }
    password_confirmation { "holama123" }
    role { 3 }
  end
end
