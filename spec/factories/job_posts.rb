FactoryBot.define do
  factory :job_post do
    sequence(:title_en) { |n| "Job Post Title #{n}" }
    sequence(:title_hi) { |n| "नौकरी पोस्ट शीर्षक #{n}" }
    description_en { Faker::Lorem.paragraphs(number: 2).join("\n\n") }
    description_hi { "यह एक परीक्षण नौकरी पोस्ट है। " * 5 }
    category { :internship }
    status { :draft }
    company_name { Faker::Company.name }
    location { "Remote" }
    deadline { 1.month.from_now.to_date }
    application_url { "https://example.com/apply" }
    association :author, factory: :user

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :full_time do
      category { :full_time }
    end

    trait :government do
      category { :government }
    end

    trait :expired do
      status { :published }
      published_at { 2.months.ago }
      deadline { 1.week.ago.to_date }
    end
  end
end
