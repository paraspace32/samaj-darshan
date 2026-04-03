FactoryBot.define do
  factory :comment do
    body { Faker::Lorem.sentence(word_count: 10) }
    association :user
    association :commentable, factory: [ :article, :published ]
  end
end
