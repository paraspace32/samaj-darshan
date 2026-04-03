require "rails_helper"

RSpec.describe "Api::V1::Articles", type: :request do
  let!(:region) { create(:region) }
  let!(:category) { create(:category) }
  let!(:published) { create(:article, :published, region: region, category: category) }
  let!(:draft) { create(:article, status: :draft) }

  describe "GET /api/v1/articles" do
    it "returns published articles as JSON" do
      get api_v1_articles_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["articles"].size).to eq(1)
      expect(json["articles"].first["id"]).to eq(published.id)
      expect(json["meta"]).to include("page", "per_page", "total", "total_pages")
    end

    it "filters by region_id" do
      other = create(:article, :published)
      get api_v1_articles_path, params: { region_id: region.id }, as: :json
      json = JSON.parse(response.body)
      ids = json["articles"].map { |a| a["id"] }
      expect(ids).to include(published.id)
      expect(ids).not_to include(other.id)
    end

    it "filters by category_id" do
      get api_v1_articles_path, params: { category_id: category.id }, as: :json
      json = JSON.parse(response.body)
      expect(json["articles"].all? { |a| a["category"]["id"] == category.id }).to be true
    end
  end

  describe "GET /api/v1/articles/:id" do
    it "returns a published article with full content" do
      get api_v1_article_path(published), as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)["article"]
      expect(json["id"]).to eq(published.id)
      expect(json["content_en"]).to be_present
    end

    it "returns 404 for draft articles" do
      get api_v1_article_path(draft), as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
