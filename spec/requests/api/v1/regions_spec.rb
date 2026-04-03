require "rails_helper"

RSpec.describe "Api::V1::Regions", type: :request do
  let!(:active_region) { create(:region, active: true) }
  let!(:inactive_region) { create(:region, active: false) }

  describe "GET /api/v1/regions" do
    it "returns only active regions" do
      get api_v1_regions_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json["regions"].map { |r| r["id"] }
      expect(ids).to include(active_region.id)
      expect(ids).not_to include(inactive_region.id)
    end
  end

  describe "GET /api/v1/regions/:id" do
    it "returns a region by slug" do
      get api_v1_region_path(active_region.slug), as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)["region"]
      expect(json["id"]).to eq(active_region.id)
    end

    it "returns 404 for unknown slug" do
      get api_v1_region_path("nonexistent"), as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
