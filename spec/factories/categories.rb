FactoryBot.define do
  factory :category do
    sequence(:name_en) { |n| "Category #{n}" }
    sequence(:name_hi) { |n| "श्रेणी #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    color { "#6366f1" }
    active { true }
    position { 0 }
  end
end
