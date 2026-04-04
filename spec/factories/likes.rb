FactoryBot.define do
  factory :like do
    association :user
    association :likeable, factory: [ :news_item, :published ]
  end
end
