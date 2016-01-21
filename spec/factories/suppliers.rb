FactoryGirl.define do
  factory :supplier do
    name { FFaker::CompanyIT.name + Time.now.getutc.to_s }
  end
end
