FactoryGirl.define do
  factory :client do
    name { FFaker::CompanyIT.name + Time.now.getutc.to_s }
  end
end
