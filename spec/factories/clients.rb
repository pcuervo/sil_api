FactoryBot.define do
  factory :client do
    name { FFaker::Company.name + Time.now.getutc.to_s }
  end
end
