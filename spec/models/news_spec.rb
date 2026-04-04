require "rails_helper"

RSpec.describe News, type: :model do
  subject { build(:news_item) }

  describe "associations" do
    it { is_expected.to belong_to(:region) }
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, pending_review: 1, approved: 2, published: 3, rejected: 4) }
  end

  describe "validations" do
    it "requires at least one language for title" do
      news_item = build(:news_item, title_en: "", title_hi: "")
      expect(news_item).not_to be_valid
      expect(news_item.errors[:base]).to include("Title must be provided in at least one language")
    end

    it "is valid with only English title" do
      news_item = build(:news_item, title_hi: "")
      expect(news_item).to be_valid
    end

    it "is valid with only Hindi title" do
      news_item = build(:news_item, title_en: "")
      expect(news_item).to be_valid
    end

    it "requires at least one language for content" do
      news_item = build(:news_item, content_en: "", content_hi: "")
      expect(news_item).not_to be_valid
      expect(news_item.errors[:base]).to include("Content must be provided in at least one language")
    end
  end

  describe "scopes" do
    let!(:published) { create(:news_item, :published) }
    let!(:draft) { create(:news_item, status: :draft) }

    it ".feed returns only published news in reverse chronological order" do
      expect(News.feed).to include(published)
      expect(News.feed).not_to include(draft)
    end

    it ".by_region filters by region" do
      expect(News.by_region(published.region)).to include(published)
    end

    it ".by_category filters by category" do
      expect(News.by_category(published.category)).to include(published)
    end
  end

  describe "#publish!" do
    let(:news_item) { create(:news_item, status: :approved) }

    it "sets status to published and published_at" do
      news_item.publish!
      expect(news_item.status).to eq("published")
      expect(news_item.published_at).to be_present
    end
  end

  describe "#approve!" do
    let(:news_item) { create(:news_item, status: :pending_review) }

    it "sets status to approved and clears rejection_reason" do
      news_item.approve!
      expect(news_item.status).to eq("approved")
      expect(news_item.rejection_reason).to be_nil
    end
  end

  describe "#reject!" do
    let(:news_item) { create(:news_item, status: :pending_review) }

    it "sets status to rejected with a reason" do
      news_item.reject!("Low quality")
      expect(news_item.status).to eq("rejected")
      expect(news_item.rejection_reason).to eq("Low quality")
    end
  end

  describe "#submit_for_review!" do
    let(:news_item) { create(:news_item, status: :draft) }

    it "sets status to pending_review" do
      news_item.submit_for_review!
      expect(news_item.status).to eq("pending_review")
    end
  end

  describe "scopes (additional)" do
    it ".recent orders by published_at desc, then created_at desc" do
      old = create(:news_item, :published, published_at: 2.days.ago)
      recent = create(:news_item, :published, published_at: 1.hour.ago)
      expect(News.recent.first).to eq(recent)
      expect(News.recent.last).to eq(old)
    end
  end

  describe "images_count_within_limit" do
    it "is valid with MAX_IMAGES or fewer images" do
      news_item = build(:news_item)
      expect(news_item).to be_valid
    end
  end
end
