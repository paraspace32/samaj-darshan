require "rails_helper"

RSpec.describe "Admin::PushNotifications", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_push_notifications_path
      expect(response).to have_http_status(:ok)
    end

    it "denies regular user" do
      login_as(regular_user)
      get admin_push_notifications_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/push_notifications" do
    before do
      login_as(super_admin)
      PushSubscription.create!(token: "t1", platform: "web", os: "android")
      PushSubscription.create!(token: "t2", platform: "pwa", os: "ios")
    end

    it "shows subscriber stats" do
      get admin_push_notifications_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/push_notifications/send" do
    before { login_as(super_admin) }

    it "queues a push notification job" do
      expect {
        post send_notification_admin_push_notifications_path, params: { title: "Breaking News", url: "/news/1" }
      }.to have_enqueued_job(SendPushNotificationsJob)
      expect(response).to redirect_to(admin_push_notifications_path)
    end
  end

  describe "POST /admin/news/:id/push" do
    before { login_as(super_admin) }

    it "queues push for a published news item" do
      news = create(:news_item, :published)
      expect {
        post admin_news_push_path(news_id: news.id)
      }.to have_enqueued_job(SendPushNotificationsJob)
    end

    it "rejects push for unpublished news" do
      news = create(:news_item, status: :draft)
      post admin_news_push_path(news_id: news.id)
      expect(response).to redirect_to(admin_news_path(news))
      expect(flash[:alert]).to include("published")
    end
  end
end
