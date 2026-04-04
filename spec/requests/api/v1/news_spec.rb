require "rails_helper"

RSpec.describe "Api::V1::News", type: :request do
  let!(:region) { create(:region) }
  let!(:category) { create(:category) }
  let!(:published) { create(:news_item, :published, region: region, category: category) }
  let!(:draft) { create(:news_item, status: :draft) }

  describe "GET /api/v1/news" do
    it "returns published news as JSON" do
      get api_v1_news_index_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["news"].size).to eq(1)
      expect(json["news"].first["id"]).to eq(published.id)
      expect(json["meta"]).to include("page", "per_page", "total", "total_pages")
    end

    it "filters by region_id" do
      other = create(:news_item, :published)
      get api_v1_news_index_path, params: { region_id: region.id }, as: :json
      json = JSON.parse(response.body)
      ids = json["news"].map { |n| n["id"] }
      expect(ids).to include(published.id)
      expect(ids).not_to include(other.id)
    end

    it "filters by category_id" do
      get api_v1_news_index_path, params: { category_id: category.id }, as: :json
      json = JSON.parse(response.body)
      expect(json["news"].all? { |n| n["category"]["id"] == category.id }).to be true
    end
  end

  describe "GET /api/v1/news/:id" do
    it "returns published news with full content" do
      get api_v1_news_path(published), as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)["news"]
      expect(json["id"]).to eq(published.id)
      expect(json["content_en"]).to be_present
    end

    it "returns 404 for draft news" do
      get api_v1_news_path(draft), as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
