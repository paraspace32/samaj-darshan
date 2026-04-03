require "rails_helper"

RSpec.describe Billboard, type: :model do
  subject { build(:billboard) }

  describe "enums" do
    it { is_expected.to define_enum_for(:billboard_type).with_values(top_banner: 0, feed_inline: 1, fullscreen_splash: 2, article_top: 3, article_mid: 4) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:billboard_type) }
  end

  describe "scopes" do
    let!(:live_banner) { create(:billboard, active: true, start_date: 1.day.ago, end_date: 1.day.from_now) }
    let!(:inactive_banner) { create(:billboard, active: false) }
    let!(:expired_banner) { create(:billboard, active: true, end_date: 1.day.ago) }
    let!(:future_banner) { create(:billboard, active: true, start_date: 1.day.from_now) }

    it ".live returns active, currently running billboards" do
      expect(Billboard.live).to include(live_banner)
      expect(Billboard.live).not_to include(inactive_banner)
      expect(Billboard.live).not_to include(expired_banner)
      expect(Billboard.live).not_to include(future_banner)
    end
  end

  describe ".for_position" do
    it "returns the highest priority live billboard for a position" do
      low = create(:billboard, billboard_type: :top_banner, priority: 1)
      high = create(:billboard, billboard_type: :top_banner, priority: 10)
      create(:billboard, billboard_type: :feed_inline, priority: 99)

      expect(Billboard.for_position(:top_banner)).to eq(high)
    end
  end

  describe "#live?" do
    it "returns true for active billboard within date range" do
      b = build(:billboard, active: true, start_date: 1.day.ago, end_date: 1.day.from_now)
      expect(b.live?).to be true
    end

    it "returns false for inactive billboard" do
      b = build(:billboard, active: false)
      expect(b.live?).to be false
    end

    it "returns false for expired billboard" do
      b = build(:billboard, active: true, end_date: 1.day.ago)
      expect(b.live?).to be false
    end
  end

  describe "#track_impression!" do
    it "increments impressions_count" do
      billboard = create(:billboard)
      expect { billboard.track_impression! }.to change { billboard.reload.impressions_count }.by(1)
    end
  end

  describe "#track_click!" do
    it "increments clicks_count" do
      billboard = create(:billboard)
      expect { billboard.track_click! }.to change { billboard.reload.clicks_count }.by(1)
    end
  end
end
