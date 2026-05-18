require "rails_helper"

RSpec.describe "PushSubscriptions", type: :request do
  describe "POST /push_subscription" do
    it "creates a new subscription" do
      expect {
        post push_subscription_path, params: { token: "new-fcm-token", platform: "web", os: "android", display_mode: "browser" }, as: :json
      }.to change(PushSubscription, :count).by(1)
      expect(response).to have_http_status(:ok)
    end

    it "updates existing subscription by token" do
      PushSubscription.create!(token: "existing-token", platform: "web", os: "unknown")
      expect {
        post push_subscription_path, params: { token: "existing-token", platform: "pwa", os: "android", display_mode: "standalone" }, as: :json
      }.not_to change(PushSubscription, :count)
      expect(response).to have_http_status(:ok)
      sub = PushSubscription.find_by(token: "existing-token")
      expect(sub.platform).to eq("pwa")
      expect(sub.os).to eq("android")
    end

    it "rejects blank token" do
      post push_subscription_path, params: { token: "", platform: "web" }, as: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "associates with current user when logged in" do
      user = create(:user)
      login_as(user)
      post push_subscription_path, params: { token: "user-token-123", platform: "pwa" }, as: :json
      expect(PushSubscription.find_by(token: "user-token-123").user).to eq(user)
    end

    it "deduplicates per user per platform" do
      user = create(:user)
      PushSubscription.create!(token: "old-token", platform: "pwa", user: user)
      login_as(user)
      post push_subscription_path, params: { token: "new-token-123", platform: "pwa" }, as: :json
      expect(PushSubscription.where(user: user, platform: "pwa").count).to eq(1)
      expect(PushSubscription.find_by(token: "new-token-123")).to be_present
      expect(PushSubscription.find_by(token: "old-token")).to be_nil
    end
  end

  describe "DELETE /push_subscription" do
    it "removes subscription by token" do
      PushSubscription.create!(token: "remove-me", platform: "web")
      expect {
        delete push_subscription_path, params: { token: "remove-me" }, as: :json
      }.to change(PushSubscription, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "succeeds even if token not found" do
      delete push_subscription_path, params: { token: "nonexistent" }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /push_subscription/log_error" do
    it "returns ok" do
      post push_subscription_log_error_path, params: { message: "Permission denied", detail: "Notification API unavailable" }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
