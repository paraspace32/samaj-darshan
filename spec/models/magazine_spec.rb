require "rails_helper"

RSpec.describe Magazine, type: :model do
  subject { build(:magazine) }

  describe "associations" do
    it { is_expected.to have_many(:magazine_articles).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title_en) }
    it { is_expected.to validate_presence_of(:title_hi) }
    it { is_expected.to validate_presence_of(:issue_number) }
    it { is_expected.to validate_uniqueness_of(:issue_number) }
    it { is_expected.to validate_numericality_of(:issue_number).is_greater_than(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1) }
  end

  describe "scopes" do
    let!(:published) { create(:magazine, :published) }
    let!(:draft) { create(:magazine, status: :draft) }

    it ".visible returns only published magazines in desc order" do
      expect(Magazine.visible).to include(published)
      expect(Magazine.visible).not_to include(draft)
    end
  end

  describe "#publish!" do
    let(:magazine) { create(:magazine) }

    it "sets status to published and published_at" do
      magazine.publish!
      expect(magazine.status).to eq("published")
      expect(magazine.published_at).to be_present
    end
  end

  describe "#display_issue" do
    it "shows volume and issue number" do
      mag = build(:magazine, volume: "2", issue_number: 5)
      expect(mag.display_issue).to eq("Vol. 2, Issue #5")
    end

    it "shows only issue number without volume" do
      mag = build(:magazine, volume: nil, issue_number: 3)
      expect(mag.display_issue).to eq("Issue #3")
    end
  end
end
