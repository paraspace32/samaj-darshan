FactoryBot.define do
  factory :like do
    association :user
    association :likeable, factory: [ :article, :published ]
  end
end
