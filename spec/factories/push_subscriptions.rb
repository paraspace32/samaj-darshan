FactoryBot.define do
  factory :push_subscription do
    sequence(:token) { |n| "fcm-token-#{n}" }
    platform { "web" }
    os { "android" }
    display_mode { "browser" }
  end
end
