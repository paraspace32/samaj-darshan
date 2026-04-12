FactoryBot.define do
  factory :education_post do
    sequence(:title_en) { |n| "Education Post Title #{n}" }
    sequence(:title_hi) { |n| "शिक्षा पोस्ट शीर्षक #{n}" }
    content_en { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    content_hi { "यह एक परीक्षण शिक्षा पोस्ट है। " * 5 }
    category { :competitive_exam }
    status { :draft }
    organization_name { "UPSC" }
    exam_date { 2.months.from_now.to_date }
    registration_deadline { 1.month.from_now.to_date }
    official_url { "https://example.com/exam" }
    association :author, factory: :user

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :board_exam do
      category { :board_exam }
      organization_name { "CBSE" }
    end

    trait :entrance_exam do
      category { :entrance_exam }
      organization_name { "NTA" }
    end
  end
end
