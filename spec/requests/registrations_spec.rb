require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /signup" do
    it "renders the signup page" do
      get signup_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /signup" do
    let(:valid_params) do
      {
        user: {
          name: "Test User",
          phone: "9876543210",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "creates a new user and logs in" do
      expect { post signup_path, params: valid_params }.to change(User, :count).by(1)
      expect(response).to redirect_to(root_path)
      expect(User.last.role).to eq("user")
      expect(User.last.status).to eq("active")
    end

    it "rejects invalid phone numbers" do
      post signup_path, params: { user: valid_params[:user].merge(phone: "0000000000") }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects mismatched passwords" do
      post signup_path, params: { user: valid_params[:user].merge(password_confirmation: "different") }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate phone numbers" do
      create(:user, phone: "9876543210")
      post signup_path, params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows multiple users to sign up without email" do
      post signup_path, params: valid_params
      expect(response).to redirect_to(root_path)

      post signup_path, params: {
        user: {
          name: "Second User",
          phone: "8765432109",
          password: "password123",
          password_confirmation: "password123"
        }
      }
      expect(response).to redirect_to(root_path)
      expect(User.where(email: nil).count).to be >= 2
    end

    context "when a registered user tries to register again" do
      let!(:existing_user) do
        create(:user, name: "Existing User", phone: "9876543210", email: "existing@example.com",
                      password: "password123", password_confirmation: "password123")
      end

      it "rejects registration with the same phone number and shows error message" do
        expect {
          post signup_path, params: {
            user: {
              name: "New Name",
              phone: existing_user.phone,
              password: "newpassword456",
              password_confirmation: "newpassword456"
            }
          }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Phone has already been taken")
      end

      it "rejects registration with the same email and shows error message" do
        expect {
          post signup_path, params: {
            user: {
              name: "New Name",
              phone: "7654321098",
              email: existing_user.email,
              password: "newpassword456",
              password_confirmation: "newpassword456"
            }
          }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Email has already been taken")
      end

      it "rejects registration with the same phone and email and shows both error messages" do
        expect {
          post signup_path, params: {
            user: {
              name: "New Name",
              phone: existing_user.phone,
              email: existing_user.email,
              password: "newpassword456",
              password_confirmation: "newpassword456"
            }
          }
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Phone has already been taken")
        expect(response.body).to include("Email has already been taken")
      end

      it "does not alter the existing user's data" do
        original_name = existing_user.name
        original_password_digest = existing_user.password_digest

        post signup_path, params: {
          user: {
            name: "Different Name",
            phone: existing_user.phone,
            password: "differentpass",
            password_confirmation: "differentpass"
          }
        }

        existing_user.reload
        expect(existing_user.name).to eq(original_name)
        expect(existing_user.password_digest).to eq(original_password_digest)
      end

      it "does not log in as the existing user when registration fails" do
        post signup_path, params: {
          user: {
            name: "New Name",
            phone: existing_user.phone,
            password: "newpassword456",
            password_confirmation: "newpassword456"
          }
        }

        get root_path
        expect(response.body).not_to include(existing_user.name)
      end
    end
  end
end
