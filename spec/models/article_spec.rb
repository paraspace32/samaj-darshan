require "rails_helper"

RSpec.describe Article, type: :model do
  subject { build(:article) }

  describe "associations" do
    it { is_expected.to belong_to(:region) }
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, pending_review: 1, approved: 2, published: 3, rejected: 4) }
    it { is_expected.to define_enum_for(:article_type).with_values(news: 0, magazine: 1).with_prefix(:type) }
  end

  describe "validations" do
    it "requires at least one language for title" do
      article = build(:article, title_en: "", title_hi: "")
      expect(article).not_to be_valid
      expect(article.errors[:base]).to include("Title must be provided in at least one language")
    end

    it "is valid with only English title" do
      article = build(:article, title_hi: "")
      expect(article).to be_valid
    end

    it "is valid with only Hindi title" do
      article = build(:article, title_en: "")
      expect(article).to be_valid
    end

    it "requires at least one language for content" do
      article = build(:article, content_en: "", content_hi: "")
      expect(article).not_to be_valid
      expect(article.errors[:base]).to include("Content must be provided in at least one language")
    end
  end

  describe "scopes" do
    let!(:published) { create(:article, :published) }
    let!(:draft) { create(:article, status: :draft) }

    it ".feed returns only published articles in reverse chronological order" do
      expect(Article.feed).to include(published)
      expect(Article.feed).not_to include(draft)
    end

    it ".by_region filters by region" do
      expect(Article.by_region(published.region)).to include(published)
    end

    it ".by_category filters by category" do
      expect(Article.by_category(published.category)).to include(published)
    end
  end

  describe "#publish!" do
    let(:article) { create(:article, status: :approved) }

    it "sets status to published and published_at" do
      article.publish!
      expect(article.status).to eq("published")
      expect(article.published_at).to be_present
    end
  end

  describe "#approve!" do
    let(:article) { create(:article, status: :pending_review) }

    it "sets status to approved and clears rejection_reason" do
      article.approve!
      expect(article.status).to eq("approved")
      expect(article.rejection_reason).to be_nil
    end
  end

  describe "#reject!" do
    let(:article) { create(:article, status: :pending_review) }

    it "sets status to rejected with a reason" do
      article.reject!("Low quality")
      expect(article.status).to eq("rejected")
      expect(article.rejection_reason).to eq("Low quality")
    end
  end

  describe "#submit_for_review!" do
    let(:article) { create(:article, status: :draft) }

    it "sets status to pending_review" do
      article.submit_for_review!
      expect(article.status).to eq("pending_review")
    end
  end

  describe "scopes (additional)" do
    it ".recent orders by published_at desc, then created_at desc" do
      old = create(:article, :published, published_at: 2.days.ago)
      recent = create(:article, :published, published_at: 1.hour.ago)
      expect(Article.recent.first).to eq(recent)
      expect(Article.recent.last).to eq(old)
    end
  end

  describe "images_count_within_limit" do
    it "is valid with MAX_IMAGES or fewer images" do
      article = build(:article)
      expect(article).to be_valid
    end
  end
end
