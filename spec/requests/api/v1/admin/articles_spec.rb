require "rails_helper"

RSpec.describe "Api::V1::Admin::Articles", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:regular_user) { create(:user) }
  let(:region) { create(:region) }
  let(:category) { create(:category) }

  describe "authentication" do
    it "returns 401 for unauthenticated requests" do
      get api_v1_admin_articles_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for regular users" do
      login_as(regular_user)
      get api_v1_admin_articles_path, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/admin/articles" do
    let!(:article) { create(:article, author: editor) }

    it "returns all articles for admin" do
      login_as(editor)
      get api_v1_admin_articles_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["articles"].size).to eq(1)
      expect(json["meta"]).to include("total")
    end

    it "filters by status" do
      create(:article, :published, author: editor)
      login_as(editor)
      get api_v1_admin_articles_path, params: { status: "published" }, as: :json
      json = JSON.parse(response.body)
      expect(json["articles"].all? { |a| a["status"] == "published" }).to be true
    end
  end

  describe "POST /api/v1/admin/articles" do
    it "creates an article" do
      login_as(editor)
      expect {
        post api_v1_admin_articles_path, params: {
          article: {
            title_en: "API Article", title_hi: "एपीआई लेख",
            content_en: "Body", content_hi: "सामग्री",
            region_id: region.id, category_id: category.id,
            article_type: "news"
          }
        }, as: :json
      }.to change(Article, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/admin/articles/:id" do
    let(:article) { create(:article, author: editor) }

    it "updates an article" do
      login_as(editor)
      patch api_v1_admin_article_path(article), params: {
        article: { title_en: "Updated via API" }
      }, as: :json
      expect(response).to have_http_status(:ok)
      expect(article.reload.title_en).to eq("Updated via API")
    end
  end

  describe "DELETE /api/v1/admin/articles/:id" do
    let!(:article) { create(:article, author: super_admin) }

    it "deletes an article" do
      login_as(super_admin)
      expect {
        delete api_v1_admin_article_path(article), as: :json
      }.to change(Article, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "member actions" do
    let(:article) { create(:article, :pending_review, author: editor) }

    it "publishes via API" do
      login_as(editor)
      patch publish_api_v1_admin_article_path(article), as: :json
      expect(article.reload.status).to eq("published")
    end

    it "approves via API" do
      login_as(editor)
      patch approve_api_v1_admin_article_path(article), as: :json
      expect(article.reload.status).to eq("approved")
    end

    it "rejects via API" do
      login_as(editor)
      patch reject_api_v1_admin_article_path(article), params: { rejection_reason: "Bad" }, as: :json
      expect(article.reload.status).to eq("rejected")
    end

    it "submits for review via API" do
      draft = create(:article, status: :draft, author: editor)
      login_as(editor)
      patch submit_for_review_api_v1_admin_article_path(draft), as: :json
      expect(draft.reload.status).to eq("pending_review")
    end
  end
end
