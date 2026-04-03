require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, phone: "9876543210", password: "password123") }

  describe "GET /login" do
    it "renders the login page" do
      get login_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects logged-in users to root" do
      login_as(user)
      get login_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects admin users to admin dashboard" do
      admin = create(:user, :super_admin)
      login_as(admin)
      get login_path
      expect(response).to redirect_to(admin_root_path)
    end
  end

  describe "POST /login" do
    it "logs in with valid credentials" do
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include(user.name)
    end

    it "rejects invalid credentials" do
      post login_path, params: { phone: user.phone, password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects blocked users" do
      user.update!(status: :blocked)
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /logout" do
    it "logs out and redirects to login" do
      login_as(user)
      get logout_path
      expect(response).to redirect_to(login_path)
    end
  end
end
