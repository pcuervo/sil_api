FactoryBot.define do
  sequence(:email) { |n| FFaker::Internet.email.downcase + n.to_s }

  factory :user do
  	first_name { "Juan" }
  	last_name { "Pérez" }
    email
    password { "holama123" }
    password_confirmation { "holama123" }
    role { 2 }
  end
end
