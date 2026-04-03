FactoryBot.define do
  factory :billboard do
    sequence(:title) { |n| "Billboard #{n}" }
    billboard_type { :top_banner }
    active { true }
    priority { 0 }
    link_url { "https://example.com" }

    after(:build) do |billboard|
      billboard.image.attach(
        io: StringIO.new("fake-image-data"),
        filename: "test.png",
        content_type: "image/png"
      )
    end
  end
end
