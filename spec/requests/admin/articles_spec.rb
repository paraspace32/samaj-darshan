require "rails_helper"

RSpec.describe "Admin::Articles", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:co_editor) { create(:user, :co_editor) }
  let(:moderator) { create(:user, :moderator) }
  let(:region) { create(:region) }
  let(:category) { create(:category) }

  describe "GET /admin/articles" do
    it "is accessible to all admin-panel users" do
      [super_admin, editor, co_editor, moderator].each do |u|
        login_as(u)
        get admin_articles_path
        expect(response).to have_http_status(:ok), "Failed for #{u.role}"
      end
    end

    it "denies access to regular users" do
      login_as(create(:user))
      get admin_articles_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/articles/new" do
    it "is accessible to content creators" do
      login_as(co_editor)
      get new_admin_article_path
      expect(response).to have_http_status(:ok)
    end

    it "denies access to moderators" do
      login_as(moderator)
      get new_admin_article_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/articles" do
    let(:valid_params) do
      {
        article: {
          title_en: "Test Title",
          title_hi: "परीक्षण",
          content_en: "Content here",
          content_hi: "सामग्री यहाँ",
          region_id: region.id,
          category_id: category.id,
          article_type: "news"
        }
      }
    end

    it "creates an article as editor" do
      login_as(editor)
      expect {
        post admin_articles_path, params: valid_params
      }.to change(Article, :count).by(1)
      expect(Article.last.author).to eq(editor)
    end
  end

  describe "PATCH /admin/articles/:id/publish" do
    let(:article) { create(:article, :approved, author: editor) }

    it "allows editor to publish" do
      login_as(editor)
      patch publish_admin_article_path(article)
      expect(article.reload.status).to eq("published")
    end

    it "denies co_editor from publishing" do
      login_as(co_editor)
      patch publish_admin_article_path(article)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /admin/articles/:id" do
    let!(:article) { create(:article, author: super_admin) }

    it "allows super_admin to delete" do
      login_as(super_admin)
      expect { delete admin_article_path(article) }.to change(Article, :count).by(-1)
    end

    it "denies editor from deleting" do
      login_as(editor)
      delete admin_article_path(article)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/articles/:id (show)" do
    let(:article) { create(:article, author: editor) }

    it "renders the article detail page" do
      login_as(editor)
      get admin_article_path(article)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/articles/:id (update)" do
    let(:article) { create(:article, author: editor) }

    it "updates the article" do
      login_as(editor)
      patch admin_article_path(article), params: { article: { title_en: "Updated Title" } }
      expect(article.reload.title_en).to eq("Updated Title")
    end

    it "rejects invalid updates" do
      login_as(editor)
      patch admin_article_path(article), params: { article: { title_en: "", title_hi: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/articles/:id/approve" do
    let(:article) { create(:article, :pending_review, author: co_editor) }

    it "allows editor to approve" do
      login_as(editor)
      patch approve_admin_article_path(article)
      expect(article.reload.status).to eq("approved")
    end

    it "denies co_editor from approving" do
      login_as(co_editor)
      patch approve_admin_article_path(article)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /admin/articles/:id/reject" do
    let(:article) { create(:article, :pending_review, author: co_editor) }

    it "allows editor to reject with reason" do
      login_as(editor)
      patch reject_admin_article_path(article), params: { rejection_reason: "Needs revision" }
      expect(article.reload.status).to eq("rejected")
      expect(article.rejection_reason).to eq("Needs revision")
    end
  end

  describe "PATCH /admin/articles/:id/submit_for_review" do
    let(:article) { create(:article, status: :draft, author: co_editor) }

    it "submits article for review" do
      login_as(co_editor)
      patch submit_for_review_admin_article_path(article)
      expect(article.reload.status).to eq("pending_review")
    end
  end

  describe "edit authorization" do
    let(:article) { create(:article, author: co_editor) }

    it "allows author (co_editor) to edit their own article" do
      login_as(co_editor)
      get edit_admin_article_path(article)
      expect(response).to have_http_status(:ok)
    end

    it "denies a different co_editor from editing" do
      other = create(:user, :co_editor)
      login_as(other)
      get edit_admin_article_path(article)
      expect(response).to redirect_to(root_path)
    end

    it "allows editor to edit any article" do
      login_as(editor)
      get edit_admin_article_path(article)
      expect(response).to have_http_status(:ok)
    end
  end
end
