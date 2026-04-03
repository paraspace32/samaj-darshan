FactoryBot.define do
  factory :article do
    sequence(:title_en) { |n| "Article Title #{n}" }
    sequence(:title_hi) { |n| "लेख शीर्षक #{n}" }
    content_en { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    content_hi { "यह एक परीक्षण लेख है। " * 10 }
    association :region
    association :category
    association :author, factory: :user
    status { :draft }
    article_type { :news }

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :pending_review do
      status { :pending_review }
    end

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
      rejection_reason { "Does not meet guidelines" }
    end
  end
end
