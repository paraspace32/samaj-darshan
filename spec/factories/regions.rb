FactoryBot.define do
  factory :region do
    sequence(:name_en) { |n| "Region #{n}" }
    sequence(:name_hi) { |n| "क्षेत्र #{n}" }
    sequence(:slug) { |n| "region-#{n}" }
    active { true }
    position { 0 }
  end
end
