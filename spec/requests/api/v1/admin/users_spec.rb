require "rails_helper"

RSpec.describe "Api::V1::Admin::Users", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }

  describe "authentication" do
    it "returns 401 for unauthenticated requests" do
      get api_v1_admin_users_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/admin/users" do
    it "lists users for admin" do
      login_as(super_admin)
      get api_v1_admin_users_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["users"]).to be_an(Array)
    end

    it "filters by role" do
      create(:user, :moderator)
      login_as(super_admin)
      get api_v1_admin_users_path, params: { role: "moderator" }, as: :json
      json = JSON.parse(response.body)
      expect(json["users"].all? { |u| u["role"] == "moderator" }).to be true
    end
  end

  describe "POST /api/v1/admin/users" do
    it "creates a user (super_admin only)" do
      login_as(super_admin)
      expect {
        post api_v1_admin_users_path, params: {
          user: { name: "API User", phone: "9222222222", password: "test1234", password_confirmation: "test1234", role: "user", status: "active" }
        }, as: :json
      }.to change(User, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "denies editor from creating users" do
      login_as(editor)
      post api_v1_admin_users_path, params: {
        user: { name: "Test", phone: "9333333333", password: "test1234", password_confirmation: "test1234", role: "user", status: "active" }
      }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/admin/users/:id/toggle_status" do
    let(:target) { create(:user) }

    it "toggles user status" do
      login_as(super_admin)
      patch toggle_status_api_v1_admin_user_path(target), as: :json
      expect(target.reload.status).to eq("blocked")
    end

    it "prevents self-blocking" do
      login_as(super_admin)
      patch toggle_status_api_v1_admin_user_path(super_admin), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/admin/users/:id" do
    it "prevents self-deletion" do
      login_as(super_admin)
      delete api_v1_admin_user_path(super_admin), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
