require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, phone: "9876543210") }

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
    it "rejects requests without firebase_id_token" do
      post login_path, params: { phone: "9876543210" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects requests with invalid phone" do
      post login_path, params: { phone: "123", firebase_id_token: "token" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "logs in an existing user and returns redirect" do
      post login_path, params: { phone: user.phone, firebase_id_token: "test_token" }, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["redirect_to"]).to eq(root_path)
      expect(session[:user_id]).to eq(user.id)
    end

    it "returns needs_name for a new phone number" do
      post login_path, params: { phone: "7777777777", firebase_id_token: "test_token" }, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["needs_name"]).to eq(true)
      expect(session[:verified_phone]).to eq("7777777777")
    end

    it "blocks a blocked user" do
      user.update!(status: :blocked)
      post login_path, params: { phone: user.phone, firebase_id_token: "test_token" }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /login/set_name (full signup flow)" do
    it "creates a new user after OTP verification" do
      post login_path, params: { phone: "7777777777", firebase_id_token: "test_token" }, as: :json
      expect(response.parsed_body["needs_name"]).to eq(true)

      expect {
        post set_name_path, params: { name: "Mamta Asati" }, as: :json
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["redirect_to"]).to eq(root_path)

      new_user = User.find_by(phone: "7777777777")
      expect(new_user.name).to eq("Mamta Asati")
      expect(session[:user_id]).to eq(new_user.id)
    end

    it "fails without a prior verified phone in session" do
      post set_name_path, params: { name: "Test User" }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "fails with blank name" do
      post login_path, params: { phone: "7777777777", firebase_id_token: "test_token" }, as: :json
      post set_name_path, params: { name: "  " }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

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

    it "shows a logged-out flash notice" do
      login_as(user)
      delete logout_path
      follow_redirect!
      expect(response.body).to include(I18n.t("flash.logged_out"))
    end

    it "works even when not logged in (no error)" do
      delete logout_path
      expect(response).to redirect_to(login_path)
    end
  end
end
