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
  end
end
