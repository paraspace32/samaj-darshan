require "rails_helper"

RSpec.describe "Registrations Hindi Translations", type: :request do
  before { cookies[:locale] = "hi" }

  describe "GET /signup in Hindi locale" do
    it "renders Hindi form labels" do
      get signup_path
      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(I18n.t("signup.name_label", locale: :hi))
      expect(body).to include(I18n.t("signup.phone_label", locale: :hi))
      expect(body).to include(I18n.t("signup.email_label", locale: :hi))
      expect(body).to include(I18n.t("signup.password_label", locale: :hi))
      expect(body).to include(I18n.t("signup.password_confirm_label", locale: :hi))
    end

    it "renders Hindi submit button text" do
      get signup_path
      expect(response.body).to include(I18n.t("signup.submit", locale: :hi))
    end

    it "renders Hindi page header and subtitle" do
      get signup_path
      body = response.body
      expect(body).to include(I18n.t("signup.header", locale: :hi))
      expect(body).to include(I18n.t("signup.sub", locale: :hi))
    end
  end

  describe "POST /signup with duplicate phone in Hindi locale" do
    let!(:existing_user) do
      create(:user, name: "Existing User", phone: "9876543210",
                    password: "password123", password_confirmation: "password123")
    end

    it "shows Hindi error message for duplicate phone without 'Translation missing'" do
      post signup_path, params: {
        user: {
          name: "New User",
          phone: existing_user.phone,
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.body
      expect(body).not_to include("Translation missing")
      expect(body).not_to include("translation missing")
      expect(body).to include(I18n.t("activerecord.errors.models.user.attributes.phone.taken", locale: :hi))
    end

    it "shows Hindi 'already registered' flash message for duplicate phone" do
      post signup_path, params: {
        user: {
          name: "New User",
          phone: existing_user.phone,
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect(response.body).to include(I18n.t("signup.already_registered", locale: :hi))
    end
  end

  describe "POST /signup with duplicate email in Hindi locale" do
    let!(:existing_user) do
      create(:user, name: "Existing User", phone: "9876543210", email: "test@example.com",
                    password: "password123", password_confirmation: "password123")
    end

    it "shows Hindi error message for duplicate email without 'Translation missing'" do
      post signup_path, params: {
        user: {
          name: "New User",
          phone: "8765432109",
          email: existing_user.email,
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.body
      expect(body).not_to include("Translation missing")
      expect(body).not_to include("translation missing")
      expect(body).to include(I18n.t("activerecord.errors.models.user.attributes.email.taken", locale: :hi))
    end
  end

  describe "POST /signup with blank fields in Hindi locale" do
    it "shows Hindi error messages for blank name and phone without 'Translation missing'" do
      post signup_path, params: {
        user: {
          name: "",
          phone: "",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.body
      expect(body).not_to include("Translation missing")
      expect(body).not_to include("translation missing")
    end
  end

  describe "POST /signup with invalid phone in Hindi locale" do
    it "shows Hindi error message for invalid phone format without 'Translation missing'" do
      post signup_path, params: {
        user: {
          name: "Test User",
          phone: "0000000000",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.body
      expect(body).not_to include("Translation missing")
      expect(body).not_to include("translation missing")
    end
  end

  describe "POST /signup with mismatched passwords in Hindi locale" do
    it "shows Hindi error message for password mismatch without 'Translation missing'" do
      post signup_path, params: {
        user: {
          name: "Test User",
          phone: "9876543210",
          password: "password123",
          password_confirmation: "differentpassword"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.body
      expect(body).not_to include("Translation missing")
      expect(body).not_to include("translation missing")
    end
  end

  describe "POST /signup with invalid email in Hindi locale" do
    it "shows Hindi error message for invalid email without 'Translation missing'" do
      post signup_path, params: {
        user: {
          name: "Test User",
          phone: "9876543210",
          email: "not-an-email",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.body
      expect(body).not_to include("Translation missing")
      expect(body).not_to include("translation missing")
    end
  end

  describe "error count display in Hindi locale" do
    it "renders Hindi error count text for single error" do
      create(:user, phone: "9876543210")
      post signup_path, params: {
        user: {
          name: "Test User",
          phone: "9876543210",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      body = response.body
      expect(body).to include(I18n.t("signup.errors_found", locale: :hi))
    end

    it "renders Hindi error count text for multiple errors" do
      post signup_path, params: {
        user: {
          name: "",
          phone: "",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      body = response.body
      expect(body).to include(I18n.t("signup.errors_plural", locale: :hi))
      expect(body).to include(I18n.t("signup.errors_found", locale: :hi))
    end
  end
end
