require "rails_helper"

RSpec.describe "PasswordResets", type: :request do
  describe "GET /password_reset" do
    it "renders the password reset page" do
      get password_reset_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("password_reset.title"))
    end

    it "includes the phone input" do
      get password_reset_path
      expect(response.body).to include('id="reset-phone"')
    end

    it "includes Firebase Auth script" do
      get password_reset_path
      expect(response.body).to include("firebase-auth.js")
    end

    it "includes recaptcha container" do
      get password_reset_path
      expect(response.body).to include('id="recaptcha-container"')
    end

    it "links back to login" do
      get password_reset_path
      expect(response.body).to include(login_path)
    end

    it "shows forgot password link on login page" do
      get login_path
      expect(response.body).to include(password_reset_path)
      expect(response.body).to include(I18n.t("password_reset.forgot_password"))
    end
  end

  describe "GET /password_reset in Hindi" do
    before { cookies[:locale] = "hi" }

    it "renders Hindi labels" do
      get password_reset_path
      body = response.body
      expect(body).to include(I18n.t("password_reset.title", locale: :hi))
      expect(body).to include(I18n.t("password_reset.subtitle", locale: :hi))
      expect(body).to include(I18n.t("password_reset.send_otp", locale: :hi))
      expect(body).not_to include("Translation missing")
    end
  end

  describe "POST /password_reset" do
    let!(:user) { create(:user, phone: "9876543210", password: "oldpassword", password_confirmation: "oldpassword") }

    it "rejects empty params" do
      post password_reset_path, params: { phone: "", firebase_id_token: "", password: "" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects unknown phone number" do
      post password_reset_path, params: { phone: "8888888888", firebase_id_token: "fake", password: "newpass123" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("password_reset.phone_not_found"))
    end

    context "with stubbed Firebase verification" do
      before do
        allow_any_instance_of(PasswordResetsController).to receive(:verify_firebase_token).and_return(true)
      end

      it "rejects short password" do
        post password_reset_path, params: { phone: user.phone, firebase_id_token: "token", password: "12345" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(I18n.t("password_reset.password_too_short"))
      end

      it "updates password and logs in" do
        post password_reset_path, params: { phone: user.phone, firebase_id_token: "token", password: "newpass123" }
        expect(response).to redirect_to(root_path)
        expect(session[:user_id]).to eq(user.id)

        user.reload
        expect(user.authenticate("newpass123")).to be_truthy
        expect(user.authenticate("oldpassword")).to be_falsey
      end

      it "shows success flash after reset" do
        post password_reset_path, params: { phone: user.phone, firebase_id_token: "token", password: "newpass123" }
        follow_redirect!
        expect(response.body).to include(I18n.t("password_reset.success"))
      end
    end

    context "with failed Firebase verification" do
      before do
        allow_any_instance_of(PasswordResetsController).to receive(:verify_firebase_token).and_return(false)
      end

      it "rejects the request" do
        post password_reset_path, params: { phone: user.phone, firebase_id_token: "bad-token", password: "newpass123" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(I18n.t("password_reset.verification_failed"))
      end

      it "does not change the password" do
        post password_reset_path, params: { phone: user.phone, firebase_id_token: "bad-token", password: "newpass123" }
        user.reload
        expect(user.authenticate("oldpassword")).to be_truthy
      end

      it "does not log in the user" do
        post password_reset_path, params: { phone: user.phone, firebase_id_token: "bad-token", password: "newpass123" }
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
