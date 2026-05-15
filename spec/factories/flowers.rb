FactoryBot.define do
  factory :flower do
    association :tribute
    association :user
  end
end
