FactoryBot.define do
  factory :project do
    name { 'Project_' + random_number }
    litobel_id { FFaker::IdentificationMX.rfc }
    client
  end
end

def random_number
  rand(0...10000).to_s
end
