FactoryBot.define do
  factory :kanyadaan_application do
    girl_name { Faker::Name.female_first_name }
    parent_name { Faker::Name.name }
    contact { "#{rand(6..9)}#{rand(100_000_000..999_999_999)}" }
    location { Faker::Address.city }
    status { :pending }
    notes { nil }

    trait :with_notes do
      notes { Faker::Lorem.sentence }
    end

    trait :reviewed do
      status { :reviewed }
    end

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
