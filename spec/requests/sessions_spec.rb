require "rails_helper"

RSpec.describe "Sessions (combined login/signup)", type: :request do
  let(:user) { create(:user, phone: "9876543210", password: "password123") }

  # ── GET /login ────────────────────────────────────────────────────────────

  describe "GET /login" do
    it "renders the combined auth page" do
      get login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("auth.title"))
    end

    it "shows the phone input field" do
      get login_path
      expect(response.body).to include('name="phone"')
    end

    it "does not show password or name fields initially" do
      get login_path
      expect(response.body).to include('id="password-field" class="hidden"')
      expect(response.body).to include('id="name-field" class="hidden"')
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

  # ── GET /signup (redirect) ────────────────────────────────────────────────

  describe "GET /signup" do
    it "redirects to /login" do
      get signup_path
      expect(response).to redirect_to("/login")
    end
  end

  # ── POST /login/check ─────────────────────────────────────────────────────

  describe "POST /login/check" do
    it "returns exists: true for an existing phone" do
      user
      post login_check_path, params: { phone: "9876543210" }, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["exists"]).to be true
    end

    it "returns exists: false for a new phone" do
      post login_check_path, params: { phone: "8888888888" }, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["exists"]).to be false
    end

    it "returns exists: false for blank phone" do
      post login_check_path, params: { phone: "" }, as: :json
      json = JSON.parse(response.body)
      expect(json["exists"]).to be false
    end

    it "rate limits after 10 requests" do
      11.times do
        post login_check_path, params: { phone: "9876543210" }, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  # ── POST /login — existing user (login) ────────────────────────────────────

  describe "POST /login (login flow)" do
    it "logs in with valid credentials" do
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to eq(user.id)
    end

    it "shows welcome back flash on successful login" do
      post login_path, params: { phone: user.phone, password: "password123" }
      follow_redirect!
      expect(response.body).to include(user.name)
    end

    it "redirects admin to admin dashboard after login" do
      admin = create(:user, :super_admin, phone: "9999999999")
      post login_path, params: { phone: admin.phone, password: "password123" }
      expect(response).to redirect_to(admin_root_path)
    end

    it "redirects to return_to path when set" do
      get edit_profile_path
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(response).to redirect_to(edit_profile_path)
    end

    it "rejects wrong password" do
      post login_path, params: { phone: user.phone, password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("flash.invalid_credentials"))
      expect(session[:user_id]).to be_nil
    end

    it "rejects blocked users" do
      user.update!(status: :blocked)
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("flash.blocked_login"))
      expect(session[:user_id]).to be_nil
    end
  end

  # ── POST /login — new user (signup) ────────────────────────────────────────

  describe "POST /login (signup flow)" do
    it "creates a new user with valid params" do
      expect {
        post login_path, params: { phone: "8765432109", name: "New User", password: "secret123" }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
    end

    it "assigns user role and active status" do
      post login_path, params: { phone: "8765432109", name: "New User", password: "secret123" }
      new_user = User.find_by(phone: "8765432109")
      expect(new_user.role).to eq("user")
      expect(new_user.status).to eq("active")
    end

    it "logs in the new user immediately" do
      post login_path, params: { phone: "8765432109", name: "New User", password: "secret123" }
      new_user = User.find_by(phone: "8765432109")
      expect(session[:user_id]).to eq(new_user.id)
    end

    it "shows success flash on signup" do
      post login_path, params: { phone: "8765432109", name: "New User", password: "secret123" }
      follow_redirect!
      expect(response.body).to include(I18n.t("signup.success"))
    end

    it "rejects signup with blank name" do
      expect {
        post login_path, params: { phone: "8765432109", name: "", password: "secret123" }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:user_id]).to be_nil
    end

    it "rejects signup with blank password" do
      expect {
        post login_path, params: { phone: "8765432109", name: "New User", password: "" }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects signup with invalid phone format" do
      expect {
        post login_path, params: { phone: "0000000000", name: "New User", password: "secret123" }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create duplicate accounts for existing phone" do
      user
      expect {
        post login_path, params: { phone: user.phone, name: "Imposter", password: "wrong" }
      }.not_to change(User, :count)
    end

    it "does not alter existing user data when login fails" do
      original_name = user.name
      original_digest = user.password_digest

      post login_path, params: { phone: user.phone, password: "wrong" }

      user.reload
      expect(user.name).to eq(original_name)
      expect(user.password_digest).to eq(original_digest)
    end
  end

  # ── DELETE /logout ──────────────────────────────────────────────────────────

  describe "DELETE /logout" do
    it "redirects to login page" do
      login_as(user)
      delete logout_path
      expect(response).to redirect_to(login_path)
    end

    it "clears the session" do
      login_as(user)
      delete logout_path
      expect(session[:user_id]).to be_nil
    end

    it "shows logged-out flash" do
      login_as(user)
      delete logout_path
      follow_redirect!
      expect(response.body).to include(I18n.t("flash.logged_out"))
    end

    it "works even when not logged in" do
      delete logout_path
      expect(response).to redirect_to(login_path)
    end
  end

  # ── Hindi locale ──────────────────────────────────────────────────────────

  describe "Hindi locale" do
    before { cookies[:locale] = "hi" }

    it "renders Hindi auth labels on the login page" do
      get login_path
      body = response.body
      expect(body).to include(I18n.t("auth.title", locale: :hi))
      expect(body).to include(I18n.t("auth.subtitle", locale: :hi))
      expect(body).to include(I18n.t("auth.phone_label", locale: :hi))
    end

    it "shows Hindi flash on successful login" do
      post login_path, params: { phone: user.phone, password: "password123" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include(I18n.t("flash.welcome_back", name: user.name, locale: :hi))
    end

    it "shows Hindi error on invalid credentials" do
      post login_path, params: { phone: user.phone, password: "wrong" }
      expect(response.body).to include(I18n.t("flash.invalid_credentials", locale: :hi))
      expect(response.body).not_to include("Translation missing")
    end

    it "shows Hindi flash on successful signup" do
      post login_path, params: { phone: "8765432109", name: "New User", password: "secret123" }
      follow_redirect!
      expect(response.body).to include(I18n.t("signup.success", locale: :hi))
    end

    it "shows Hindi error on signup validation failure" do
      post login_path, params: { phone: "8765432109", name: "", password: "secret123" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("Translation missing")
    end
  end
end
