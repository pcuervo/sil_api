FactoryBot.define do
  factory :project do
    name { "#{random_number}-#{FFaker::Address.street_address}" }
    litobel_id { FFaker::Vehicle.vin }
    client
  end
end

def random_number
  rand(0...10000).to_s
end
