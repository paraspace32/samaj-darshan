require "rails_helper"

RSpec.describe "Admin::Analytics", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:regular) { create(:user) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_analytics_path
      expect(response).to have_http_status(:ok)
    end

    it "denies editor" do
      login_as(editor)
      get admin_analytics_path
      expect(response).to redirect_to(admin_root_path)
    end

    it "denies regular user" do
      login_as(regular)
      get admin_analytics_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/analytics" do
    before do
      login_as(super_admin)
      create(:visit, path: "/news/1", visited_at: Time.current, city: "Indore")
      create(:visit, path: "/news/1", visited_at: Time.current, city: "Indore")
      create(:visit, :bot, path: "/", visited_at: Time.current)
    end

    it "shows analytics stats" do
      get admin_analytics_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visitor Analytics")
      expect(response.body).to include("Today")
      expect(response.body).to include("Top Pages")
      expect(response.body).to include("Top Cities")
    end
  end
end
