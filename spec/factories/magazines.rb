FactoryBot.define do
  factory :magazine do
    sequence(:title_en) { |n| "Community Voices Issue #{n}" }
    sequence(:title_hi) { |n| "समुदाय की आवाज़ अंक #{n}" }
    description_en { "A collection of stories from the community" }
    description_hi { "समुदाय की कहानियों का संग्रह" }
    sequence(:issue_number) { |n| n }
    volume { "1" }
    status { :draft }

    trait :published do
      status { :published }
      published_at { Time.current }
    end
  end

  factory :magazine_article do
    association :magazine
    association :author, factory: :user
    sequence(:title_en) { |n| "Magazine Article #{n}" }
    sequence(:title_hi) { |n| "मैगज़ीन लेख #{n}" }
    content_en { "Article content in English for the magazine" }
    content_hi { "मैगज़ीन के लिए हिंदी में लेख सामग्री" }
    sequence(:position) { |n| n - 1 }
  end
end
