require "rails_helper"

RSpec.describe "Api::V1::Admin::Categories", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  describe "GET /api/v1/admin/categories" do
    it "returns all categories" do
      create(:category)
      login_as(super_admin)
      get api_v1_admin_categories_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["categories"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/admin/categories" do
    it "creates a category" do
      login_as(super_admin)
      expect {
        post api_v1_admin_categories_path, params: { category: { name_en: "API Cat", name_hi: "एपीआई श्रेणी", color: "#ff0000" } }, as: :json
      }.to change(Category, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/admin/categories/:id" do
    let(:cat) { create(:category) }

    it "updates a category" do
      login_as(super_admin)
      patch api_v1_admin_category_path(id: cat.id), params: { category: { name_en: "Updated Cat" } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(cat.reload.name_en).to eq("Updated Cat")
    end
  end

  describe "PATCH /api/v1/admin/categories/:id/toggle_active" do
    let(:cat) { create(:category, active: true) }

    it "toggles active" do
      login_as(super_admin)
      patch toggle_active_api_v1_admin_category_path(id: cat.id), as: :json
      expect(cat.reload.active).to be false
    end
  end
end
