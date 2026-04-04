require "rails_helper"

RSpec.describe "Api::V1::Admin::News", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:regular_user) { create(:user) }
  let(:region) { create(:region) }
  let(:category) { create(:category) }

  describe "authentication" do
    it "returns 401 for unauthenticated requests" do
      get api_v1_admin_news_index_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for regular users" do
      login_as(regular_user)
      get api_v1_admin_news_index_path, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/admin/news" do
    let!(:news_item) { create(:news_item, author: editor) }

    it "returns all news for admin" do
      login_as(editor)
      get api_v1_admin_news_index_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["news"].size).to eq(1)
      expect(json["meta"]).to include("total")
    end

    it "filters by status" do
      create(:news_item, :published, author: editor)
      login_as(editor)
      get api_v1_admin_news_index_path, params: { status: "published" }, as: :json
      json = JSON.parse(response.body)
      expect(json["news"].all? { |n| n["status"] == "published" }).to be true
    end
  end

  describe "POST /api/v1/admin/news" do
    it "creates news" do
      login_as(editor)
      expect {
        post api_v1_admin_news_index_path, params: {
          news: {
            title_en: "API News", title_hi: "एपीआई समाचार",
            content_en: "Body", content_hi: "सामग्री",
            region_id: region.id, category_id: category.id
          }
        }, as: :json
      }.to change(News, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/admin/news/:id" do
    let(:news_item) { create(:news_item, author: editor) }

    it "updates news" do
      login_as(editor)
      patch api_v1_admin_news_path(news_item), params: {
        news: { title_en: "Updated via API" }
      }, as: :json
      expect(response).to have_http_status(:ok)
      expect(news_item.reload.title_en).to eq("Updated via API")
    end
  end

  describe "DELETE /api/v1/admin/news/:id" do
    let!(:news_item) { create(:news_item, author: super_admin) }

    it "deletes news" do
      login_as(super_admin)
      expect {
        delete api_v1_admin_news_path(news_item), as: :json
      }.to change(News, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "member actions" do
    let(:news_item) { create(:news_item, :pending_review, author: editor) }

    it "publishes via API" do
      login_as(editor)
      patch publish_api_v1_admin_news_path(news_item), as: :json
      expect(news_item.reload.status).to eq("published")
    end

    it "approves via API" do
      login_as(editor)
      patch approve_api_v1_admin_news_path(news_item), as: :json
      expect(news_item.reload.status).to eq("approved")
    end

    it "rejects via API" do
      login_as(editor)
      patch reject_api_v1_admin_news_path(news_item), params: { rejection_reason: "Bad" }, as: :json
      expect(news_item.reload.status).to eq("rejected")
    end

    it "submits for review via API" do
      draft = create(:news_item, status: :draft, author: editor)
      login_as(editor)
      patch submit_for_review_api_v1_admin_news_path(draft), as: :json
      expect(draft.reload.status).to eq("pending_review")
    end
  end
end
