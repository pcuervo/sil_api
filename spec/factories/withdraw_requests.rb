FactoryGirl.define do
  factory :withdraw_request do
    user
    exit_date { FFaker::Time.date }
    pickup_company_id 1
  end
end
