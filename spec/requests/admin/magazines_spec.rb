require "rails_helper"

RSpec.describe "Admin::Magazines", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:regular_user) { create(:user) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_magazines_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor with magazines section access" do
      login_as(editor)
      get admin_magazines_path
      expect(response).to have_http_status(:ok)
    end

    it "denies regular user" do
      login_as(regular_user)
      get admin_magazines_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/magazines" do
    before { login_as(super_admin) }

    it "lists magazines" do
      create(:magazine, :published)
      get admin_magazines_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      get admin_magazines_path, params: { status: "published" }
      expect(response).to have_http_status(:ok)
    end

    it "searches by title" do
      create(:magazine, title_en: "Community Voices Special")
      get admin_magazines_path, params: { q: "Special" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Special")
    end
  end

  describe "POST /admin/magazines" do
    before { login_as(super_admin) }

    it "creates a new magazine" do
      expect {
        post admin_magazines_path, params: {
          magazine: {
            title_en: "New Issue",
            title_hi: "नया अंक",
            issue_number: 99
          }
        }
      }.to change(Magazine, :count).by(1)
      expect(response).to redirect_to(admin_magazine_path(Magazine.last))
    end

    it "re-renders form on validation error" do
      post admin_magazines_path, params: {
        magazine: { title_en: "", issue_number: nil }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/magazines/:id" do
    let(:magazine) { create(:magazine) }

    before { login_as(super_admin) }

    it "updates the magazine" do
      patch admin_magazine_path(magazine), params: {
        magazine: { title_en: "Updated Title" }
      }
      expect(magazine.reload.title_en).to eq("Updated Title")
      expect(response).to redirect_to(admin_magazine_path(magazine))
    end
  end

  describe "DELETE /admin/magazines/:id" do
    let!(:magazine) { create(:magazine) }

    before { login_as(super_admin) }

    it "deletes the magazine" do
      expect {
        delete admin_magazine_path(magazine)
      }.to change(Magazine, :count).by(-1)
    end
  end

  describe "PATCH /admin/magazines/:id/publish" do
    let(:magazine) { create(:magazine) }

    before { login_as(super_admin) }

    it "publishes the magazine" do
      patch publish_admin_magazine_path(magazine)
      expect(magazine.reload).to be_published
    end
  end

  # ── Nested Magazine Articles ──────────────────────────────────────────────

  describe "POST /admin/magazines/:magazine_id/magazine_articles" do
    let(:magazine) { create(:magazine) }

    before { login_as(super_admin) }

    it "creates a new article" do
      expect {
        post admin_magazine_magazine_articles_path(magazine), params: {
          magazine_article: {
            title_en: "Article Title",
            content_en: "Article body content",
            position: 0
          }
        }
      }.to change(MagazineArticle, :count).by(1)
      expect(response).to redirect_to(admin_magazine_path(magazine))
    end

    it "re-renders form on validation error" do
      post admin_magazine_magazine_articles_path(magazine), params: {
        magazine_article: { title_en: "", content_en: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/magazines/:magazine_id/magazine_articles/:id" do
    let(:magazine) { create(:magazine) }
    let(:article) { create(:magazine_article, magazine: magazine) }

    before { login_as(super_admin) }

    it "updates the article" do
      patch admin_magazine_magazine_article_path(magazine, article), params: {
        magazine_article: { title_en: "Updated Article" }
      }
      expect(article.reload.title_en).to eq("Updated Article")
      expect(response).to redirect_to(admin_magazine_path(magazine))
    end
  end

  describe "DELETE /admin/magazines/:magazine_id/magazine_articles/:id" do
    let(:magazine) { create(:magazine) }
    let!(:article) { create(:magazine_article, magazine: magazine) }

    before { login_as(super_admin) }

    it "deletes the article" do
      expect {
        delete admin_magazine_magazine_article_path(magazine, article)
      }.to change(MagazineArticle, :count).by(-1)
    end
  end
end
