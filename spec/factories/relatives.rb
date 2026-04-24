FactoryBot.define do
  factory :relative do
    association :biodata
    relative_type { "Bhaiya" }
    name          { "Ramesh Kumar" }
  end
end
