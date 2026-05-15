FactoryBot.define do
  factory :tribute do
    sequence(:name_en) { |n| "Tribute Person #{n}" }
    sequence(:name_hi) { |n| "श्रद्धांजलि #{n}" }
    description_en { "A beloved member of our community." }
    description_hi { "हमारे समुदाय के एक प्रिय सदस्य।" }
    association :created_by, factory: [ :user, :super_admin ]

    after(:build) do |tribute|
      tribute.image.attach(
        io: StringIO.new("fake-image-data"),
        filename: "tribute.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end
