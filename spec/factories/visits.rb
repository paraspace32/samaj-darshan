FactoryBot.define do
  factory :visit do
    visitor_token { Digest::SHA256.hexdigest("#{Faker::Internet.ip_v4_address}||#{Faker::Internet.user_agent}") }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    path { "/news/#{rand(1..100)}" }
    bot { false }
    visited_at { Time.current }

    trait :bot do
      user_agent { "Googlebot/2.1" }
      bot { true }
    end
  end
end
