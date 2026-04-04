FactoryBot.define do
  factory :webinar do
    sequence(:title_en) { |n| "Webinar Title #{n}" }
    sequence(:title_hi) { |n| "वेबिनार शीर्षक #{n}" }
    description_en { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    description_hi { "यह एक परीक्षण वेबिनार है। " * 5 }
    speaker_name { Faker::Name.name }
    speaker_bio { Faker::Lorem.sentence }
    platform { :zoom }
    status { :draft }
    starts_at { 3.days.from_now }
    duration_minutes { 60 }
    meeting_url { "https://zoom.us/j/1234567890" }
    association :host, factory: :user

    trait :published do
      status { :published }
    end

    trait :upcoming do
      status { :published }
      starts_at { 3.days.from_now }
    end

    trait :past do
      status { :published }
      starts_at { 3.days.ago }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
