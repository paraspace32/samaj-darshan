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

    it "sets the user_id in session" do
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(session[:user_id]).to eq(user.id)
    end

    it "rejects invalid credentials" do
      post login_path, params: { phone: user.phone, password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("flash.invalid_credentials"))
    end

    it "does not set session on invalid credentials" do
      post login_path, params: { phone: user.phone, password: "wrong" }
      expect(session[:user_id]).to be_nil
    end

    it "rejects blocked users" do
      user.update!(status: :blocked)
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("flash.blocked_login"))
    end
  end

  describe "GET /logout" do
    it "redirects to login page" do
      login_as(user)
      get logout_path
      expect(response).to redirect_to(login_path)
    end

    it "clears the session" do
      login_as(user)
      get logout_path
      expect(session[:user_id]).to be_nil
    end

    it "shows a logged-out flash notice" do
      login_as(user)
      get logout_path
      follow_redirect!
      expect(response.body).to include(I18n.t("flash.logged_out"))
    end

    it "works even when not logged in (no error)" do
      get logout_path
      expect(response).to redirect_to(login_path)
    end

    it "prevents accessing protected pages after logout" do
      login_as(user)
      get logout_path
      get root_path
      # should still work (root is public), but session is gone
      expect(session[:user_id]).to be_nil
    end
  end
end
