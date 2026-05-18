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
      create(:visit, path: "/news/1", visited_at: Time.current, city: "Indore", device_type: "mobile")
      create(:visit, path: "/news/1", visited_at: Time.current, city: "Indore", device_type: "mobile")
      create(:visit, path: "/jobs/5", visited_at: Time.current, city: "Bhopal", device_type: "desktop")
      create(:visit, :bot, path: "/", visited_at: Time.current)
    end

    it "shows analytics stats" do
      get admin_analytics_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visitor Analytics")
      expect(response.body).to include("Today")
      expect(response.body).to include("Top Pages")
      expect(response.body).to include("Top Cities")
      expect(response.body).to include("Filters")
    end

    it "shows filter form elements" do
      get admin_analytics_path
      expect(response.body).to include("Date Range")
      expect(response.body).to include("City")
      expect(response.body).to include("Device")
      expect(response.body).to include("Page Path")
      expect(response.body).to include("Apply Filters")
    end

    it "filters by date range" do
      create(:visit, path: "/old", visited_at: 2.months.ago, city: "Delhi")
      get admin_analytics_path, params: { range: "today" }
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("/old")
    end

    it "filters by city" do
      get admin_analytics_path, params: { city: "Indore" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Clear all")
    end

    it "filters by device type" do
      get admin_analytics_path, params: { device: "mobile" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Clear all")
    end

    it "filters by path" do
      get admin_analytics_path, params: { path: "/news" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Clear all")
    end

    it "supports custom date range" do
      get admin_analytics_path, params: { range: "custom", from: 1.week.ago.to_date.to_s, to: Date.today.to_s }
      expect(response).to have_http_status(:ok)
    end

    it "combines multiple filters" do
      get admin_analytics_path, params: { range: "last_30", city: "Indore", device: "mobile" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Clear all")
    end

    it "populates city dropdown from visit data" do
      get admin_analytics_path
      expect(response.body).to include("Indore")
      expect(response.body).to include("Bhopal")
    end

    it "populates device dropdown from visit data" do
      get admin_analytics_path
      expect(response.body).to include("Mobile")
      expect(response.body).to include("Desktop")
    end
  end
end
