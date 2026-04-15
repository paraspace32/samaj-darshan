FactoryBot.define do
  factory :shortlist do
    association :user
    association :biodata, factory: [ :biodata, :published ]
  end
end
