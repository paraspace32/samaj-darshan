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

    trait :live do
      status { :published }
      starts_at { 30.minutes.ago }
      duration_minutes { 120 }
    end

    trait :with_registration do
      registration_url { "https://webinar.zoho.in/meeting/register/embed?sessionId=1234" }
    end

    trait :with_youtube do
      meeting_url { "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }
    end

    trait :with_youtube_live do
      meeting_url { "https://youtube.com/live/abc123live" }
    end

    trait :past_with_recording do
      status { :published }
      starts_at { 3.days.ago }
      meeting_url { "https://www.youtube.com/watch?v=recorded123" }
    end
  end
end
