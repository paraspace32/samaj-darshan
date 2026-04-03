require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    it "redirects unauthenticated users to login" do
      get admin_root_path
      expect(response).to redirect_to(login_path)
    end

    it "denies access to regular users" do
      login_as(create(:user))
      get admin_root_path
      expect(response).to redirect_to(root_path)
    end

    it "allows super_admin access" do
      login_as(create(:user, :super_admin))
      get admin_root_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor access" do
      login_as(create(:user, :editor))
      get admin_root_path
      expect(response).to have_http_status(:ok)
    end

    it "allows moderator access" do
      login_as(create(:user, :moderator))
      get admin_root_path
      expect(response).to have_http_status(:ok)
    end
  end
end
