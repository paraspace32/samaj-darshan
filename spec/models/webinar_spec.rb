require "rails_helper"

RSpec.describe Webinar, type: :model do
  describe "validations" do
    it "is invalid without title_en and title_hi" do
      webinar = build(:webinar, title_en: nil, title_hi: nil)
      expect(webinar).not_to be_valid
      expect(webinar.errors[:title_en]).to be_present
    end

    it "is invalid without description_en and description_hi" do
      webinar = build(:webinar, description_en: nil, description_hi: nil)
      expect(webinar).not_to be_valid
      expect(webinar.errors[:description_en]).to be_present
    end

    it { is_expected.to validate_presence_of(:speaker_name) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:duration_minutes) }
    it { is_expected.to validate_numericality_of(:duration_minutes).is_greater_than(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:host).class_name("User") }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1, cancelled: 2) }
    it { is_expected.to define_enum_for(:platform).with_values(zoom: 0, google_meet: 1, youtube_live: 2, other: 3, zoho: 4) }
  end

  describe "scopes" do
    let!(:upcoming) { create(:webinar, :upcoming) }
    let!(:past) { create(:webinar, :past) }
    let!(:draft) { create(:webinar) }

    it "returns only upcoming published webinars" do
      expect(Webinar.upcoming).to include(upcoming)
      expect(Webinar.upcoming).not_to include(past)
      expect(Webinar.upcoming).not_to include(draft)
    end

    it "returns only past published webinars" do
      expect(Webinar.past).to include(past)
      expect(Webinar.past).not_to include(upcoming)
    end
  end

  describe "instance methods" do
    let(:webinar) { build(:webinar, starts_at: 1.hour.from_now, duration_minutes: 60) }

    it "#upcoming? returns true for future webinars" do
      expect(webinar.upcoming?).to be true
    end

    it "#ended? returns true for past webinars" do
      webinar.starts_at = 3.hours.ago
      expect(webinar.ended?).to be true
    end

    it "#ends_at returns correct end time" do
      expect(webinar.ends_at).to eq(webinar.starts_at + 60.minutes)
    end

    it "#live_now? returns true during the webinar" do
      webinar.starts_at = 30.minutes.ago
      expect(webinar.live_now?).to be true
    end

    it "#joinable? returns false when webinar is far away" do
      webinar.starts_at = 1.hour.from_now
      expect(webinar.joinable?).to be false
    end

    it "#joinable? returns true when webinar starts within 15 min" do
      webinar.starts_at = 10.minutes.from_now
      expect(webinar.joinable?).to be true
    end

    it "#joinable? returns true when webinar is live" do
      webinar.starts_at = 30.minutes.ago
      expect(webinar.joinable?).to be true
    end
  end

  describe "#primary_action" do
    context "upcoming webinar with registration URL" do
      let(:webinar) { build(:webinar, :upcoming, :with_registration) }

      it "returns :registration" do
        expect(webinar.primary_action).to eq(:registration)
      end
    end

    context "upcoming webinar with YouTube live URL" do
      let(:webinar) { build(:webinar, :upcoming, :with_youtube_live) }

      it "returns :youtube_live" do
        expect(webinar.primary_action).to eq(:youtube_live)
      end
    end

    context "upcoming webinar with registration AND YouTube" do
      let(:webinar) { build(:webinar, :upcoming, :with_registration, :with_youtube) }

      it "prioritizes :registration over youtube" do
        expect(webinar.primary_action).to eq(:registration)
      end
    end

    context "live webinar with YouTube embed" do
      let(:webinar) { build(:webinar, :live, :with_youtube_live) }

      it "returns :youtube_live" do
        expect(webinar.primary_action).to eq(:youtube_live)
      end
    end

    context "live webinar with Zoom link" do
      let(:webinar) { build(:webinar, :live, meeting_url: "https://zoom.us/j/123") }

      it "returns :join_link" do
        expect(webinar.primary_action).to eq(:join_link)
      end
    end

    context "upcoming webinar with no links" do
      let(:webinar) { build(:webinar, :upcoming, meeting_url: nil, registration_url: nil) }

      it "returns :info" do
        expect(webinar.primary_action).to eq(:info)
      end
    end

    context "ended webinar with YouTube recording" do
      let(:webinar) { build(:webinar, :past_with_recording) }

      it "returns :recording" do
        expect(webinar.primary_action).to eq(:recording)
      end
    end

    context "ended webinar without recording" do
      let(:webinar) { build(:webinar, :past, meeting_url: "https://zoom.us/j/123") }

      it "returns :ended" do
        expect(webinar.primary_action).to eq(:ended)
      end
    end

    context "ended webinar with no meeting URL" do
      let(:webinar) { build(:webinar, :past, meeting_url: nil) }

      it "returns :ended" do
        expect(webinar.primary_action).to eq(:ended)
      end
    end
  end

  describe "youtube embedding" do
    let(:webinar) { build(:webinar) }

    it "extracts embed URL from youtube.com/live/ URL" do
      webinar.meeting_url = "https://youtube.com/live/abc123"
      expect(webinar.youtube_embed_url).to eq("https://www.youtube.com/embed/abc123")
      expect(webinar.embeddable?).to be true
    end

    it "extracts embed URL from youtu.be short URL" do
      webinar.meeting_url = "https://youtu.be/xyz789"
      expect(webinar.youtube_embed_url).to eq("https://www.youtube.com/embed/xyz789")
    end

    it "extracts embed URL from youtube.com?v= URL" do
      webinar.meeting_url = "https://www.youtube.com/watch?v=test456"
      expect(webinar.youtube_embed_url).to eq("https://www.youtube.com/embed/test456")
    end

    it "embeds regardless of platform setting" do
      webinar.platform = :other
      webinar.meeting_url = "https://www.youtube.com/watch?v=abc123"
      expect(webinar.embeddable?).to be true
    end

    it "returns nil for non-youtube URLs" do
      webinar.meeting_url = "https://zoom.us/j/123"
      expect(webinar.youtube_embed_url).to be_nil
      expect(webinar.embeddable?).to be false
    end
  end
end
