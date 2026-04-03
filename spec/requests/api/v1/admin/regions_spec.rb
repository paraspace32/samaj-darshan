require "rails_helper"

RSpec.describe "Api::V1::Admin::Regions", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  describe "GET /api/v1/admin/regions" do
    it "returns all regions" do
      create(:region)
      login_as(super_admin)
      get api_v1_admin_regions_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["regions"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/admin/regions" do
    it "creates a region" do
      login_as(super_admin)
      expect {
        post api_v1_admin_regions_path, params: { region: { name_en: "API Region", name_hi: "एपीआई क्षेत्र" } }, as: :json
      }.to change(Region, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/admin/regions/:id" do
    let(:region) { create(:region) }

    it "updates a region" do
      login_as(super_admin)
      patch api_v1_admin_region_path(id: region.id), params: { region: { name_en: "Updated Region" } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(region.reload.name_en).to eq("Updated Region")
    end
  end

  describe "PATCH /api/v1/admin/regions/:id/toggle_active" do
    let(:region) { create(:region, active: true) }

    it "toggles active" do
      login_as(super_admin)
      patch toggle_active_api_v1_admin_region_path(id: region.id), as: :json
      expect(region.reload.active).to be false
    end
  end
end
