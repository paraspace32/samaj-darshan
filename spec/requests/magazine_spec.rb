require "rails_helper"

RSpec.describe "Magazine", type: :request do
  let(:region) { create(:region) }
  let(:category) { create(:category) }

  describe "GET /magazine" do
    it "renders the magazine feed" do
      create(:article, :published, :magazine, region: region, category: category)
      get magazine_path
      expect(response).to have_http_status(:ok)
    end

    it "does not show news articles" do
      news = create(:article, :published, article_type: :news, region: region, category: category)
      mag = create(:article, :published, :magazine, region: region, category: category)
      get magazine_path
      expect(response.body).to include(mag.display_title)
      expect(response.body).not_to include(news.display_title)
    end

    it "filters by category" do
      other_category = create(:category, name_en: "Other Cat", name_hi: "अन्य", slug: "other-cat", color: "#333")
      mag1 = create(:article, :published, :magazine, region: region, category: category)
      mag2 = create(:article, :published, :magazine, region: region, category: other_category)
      get magazine_path(category: category.slug)
      expect(response.body).to include(mag1.display_title)
      expect(response.body).not_to include(mag2.display_title)
    end

    it "renders empty state when no articles" do
      get magazine_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /magazine/:id" do
    let(:article) { create(:article, :published, :magazine, region: region, category: category) }

    it "renders the magazine article" do
      get magazine_article_path(article)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(article.display_title)
    end

    it "returns 404 for news articles" do
      news = create(:article, :published, article_type: :news, region: region, category: category)
      get magazine_article_path(news)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unpublished magazine articles" do
      draft = create(:article, :magazine, status: :draft, region: region, category: category)
      get magazine_article_path(draft)
      expect(response).to have_http_status(:not_found)
    end
  end
end
