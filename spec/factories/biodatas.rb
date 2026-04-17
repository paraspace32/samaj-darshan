FactoryBot.define do
  factory :biodata do
    association :user
    full_name     { Faker::Name.name }
    full_name_hi  { nil }
    gender        { :male }
    date_of_birth { 28.years.ago.to_date }
    city          { "Indore" }
    state         { "Madhya Pradesh" }
    education     { "B.Tech" }
    status        { :draft }

    trait :published do
      status       { :published }
      published_at { Time.current }
    end

    trait :female do
      gender { :female }
    end

    trait :with_contact do
      contact_phone { "9876543210" }
      contact_email { Faker::Internet.email }
    end

    trait :with_partner_expectations do
      partner_age_min        { 24 }
      partner_age_max        { 30 }
      partner_education      { "Graduate" }
      partner_occupation     { "Any" }
      partner_expectations   { "Looking for a kind and caring partner." }
    end

    trait :pending_consent do
      status { :pending_consent }
    end
  end
end
