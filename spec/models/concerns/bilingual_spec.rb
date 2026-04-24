require "rails_helper"

RSpec.describe Bilingual, type: :model do
  describe ".bilingual_field" do
    let(:region) { create(:region, name_en: "Mumbai", name_hi: "मुंबई") }

    context "when locale is :en" do
      before { I18n.locale = :en }
      after  { I18n.locale = I18n.default_locale }

      it "returns English name first" do
        expect(region.display_name).to eq("Mumbai")
      end

      it "falls back to Hindi when English is blank" do
        region.update_column(:name_en, "")
        expect(region.display_name).to eq("मुंबई")
      end
    end

    context "when locale is :hi" do
      before { I18n.locale = :hi }
      after  { I18n.locale = I18n.default_locale }

      it "returns Hindi name first" do
        expect(region.display_name).to eq("मुंबई")
      end

      it "falls back to English when Hindi is blank" do
        region.update_column(:name_hi, "")
        expect(region.display_name).to eq("Mumbai")
      end
    end
  end

  # ─── News-specific bilingual behaviour (title + content) ─────────────────
  describe "News bilingual fields" do
    let(:region)   { create(:region) }
    let(:category) { create(:category) }

    let(:news_item) do
      create(:news_item, :published,
        region:     region,
        category:   category,
        title_en:   "English Title",
        title_hi:   "हिंदी शीर्षक",
        content_en: "English content.",
        content_hi: "हिंदी सामग्री।")
    end

    context "display_title" do
      after { I18n.locale = I18n.default_locale }

      it "returns title_en when locale is :en" do
        I18n.locale = :en
        expect(news_item.display_title).to eq("English Title")
      end

      it "returns title_hi when locale is :hi" do
        I18n.locale = :hi
        expect(news_item.display_title).to eq("हिंदी शीर्षक")
      end

      it "matches title_en.presence || title_hi for :en locale (mirrors OG tag logic)" do
        I18n.locale = :en
        expected = news_item.title_en.presence || news_item.title_hi
        expect(news_item.display_title).to eq(expected)
      end

      it "falls back to title_en when title_hi is blank and locale is :hi" do
        I18n.locale = :hi
        news_item.update_columns(title_hi: "")
        expect(news_item.display_title).to eq("English Title")
      end

      it "falls back to title_hi when title_en is blank and locale is :en" do
        I18n.locale = :en
        news_item.update_columns(title_en: "")
        expect(news_item.display_title).to eq("हिंदी शीर्षक")
      end
    end

    context "display_content" do
      after { I18n.locale = I18n.default_locale }

      it "returns content_en when locale is :en" do
        I18n.locale = :en
        expect(news_item.display_content).to eq("English content.")
      end

      it "returns content_hi when locale is :hi" do
        I18n.locale = :hi
        expect(news_item.display_content).to eq("हिंदी सामग्री।")
      end

      it "falls back to content_en when content_hi is blank and locale is :hi" do
        I18n.locale = :hi
        news_item.update_columns(content_hi: "")
        expect(news_item.display_content).to eq("English content.")
      end

      it "falls back to content_hi when content_en is blank and locale is :en" do
        I18n.locale = :en
        news_item.update_columns(content_en: "")
        expect(news_item.display_content).to eq("हिंदी सामग्री।")
      end
    end
  end
end
