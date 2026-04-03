FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    phone { "#{rand(6..9)}#{rand(100_000_000..999_999_999)}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :user }
    status { :active }

    trait :super_admin do
      role { :super_admin }
    end

    trait :editor do
      role { :editor }
    end

    trait :co_editor do
      role { :co_editor }
    end

    trait :moderator do
      role { :moderator }
    end

    trait :blocked do
      status { :blocked }
    end
  end
end
