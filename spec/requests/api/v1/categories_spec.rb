require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  let!(:active_cat) { create(:category, active: true) }
  let!(:inactive_cat) { create(:category, active: false) }

  describe "GET /api/v1/categories" do
    it "returns only active categories" do
      get api_v1_categories_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json["categories"].map { |c| c["id"] }
      expect(ids).to include(active_cat.id)
      expect(ids).not_to include(inactive_cat.id)
    end
  end

  describe "GET /api/v1/categories/:id" do
    it "returns a category by slug" do
      get api_v1_category_path(active_cat.slug), as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)["category"]
      expect(json["id"]).to eq(active_cat.id)
      expect(json["color"]).to eq(active_cat.color)
    end

    it "returns 404 for unknown slug" do
      get api_v1_category_path("nonexistent"), as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
