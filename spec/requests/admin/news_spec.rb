require "rails_helper"

RSpec.describe "Admin::News", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:co_editor) { create(:user, :co_editor) }
  let(:moderator) { create(:user, :moderator) }
  let(:region) { create(:region) }
  let(:category) { create(:category) }

  describe "GET /admin/news" do
    it "is accessible to all admin-panel users" do
      [ super_admin, editor, co_editor, moderator ].each do |u|
        login_as(u)
        get admin_news_index_path
        expect(response).to have_http_status(:ok), "Failed for #{u.role}"
      end
    end

    it "denies access to regular users" do
      login_as(create(:user))
      get admin_news_index_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/news/new" do
    it "is accessible to content creators" do
      login_as(co_editor)
      get new_admin_news_path
      expect(response).to have_http_status(:ok)
    end

    it "denies access to moderators" do
      login_as(moderator)
      get new_admin_news_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/news" do
    let(:valid_params) do
      {
        news: {
          title_en: "Test Title",
          title_hi: "परीक्षण",
          content_en: "Content here",
          content_hi: "सामग्री यहाँ",
          region_id: region.id,
          category_id: category.id
        }
      }
    end

    it "creates news as editor" do
      login_as(editor)
      expect {
        post admin_news_index_path, params: valid_params
      }.to change(News, :count).by(1)
      expect(News.last.author).to eq(editor)
    end
  end

  describe "PATCH /admin/news/:id/publish" do
    let(:news_item) { create(:news_item, :approved, author: editor) }

    it "allows editor to publish" do
      login_as(editor)
      patch publish_admin_news_path(news_item)
      expect(news_item.reload.status).to eq("published")
    end

    it "denies co_editor from publishing" do
      login_as(co_editor)
      patch publish_admin_news_path(news_item)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /admin/news/:id" do
    let!(:news_item) { create(:news_item, author: super_admin) }

    it "allows super_admin to delete" do
      login_as(super_admin)
      expect { delete admin_news_path(news_item) }.to change(News, :count).by(-1)
    end

    it "denies editor from deleting" do
      login_as(editor)
      delete admin_news_path(news_item)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/news/:id (show)" do
    let(:news_item) { create(:news_item, author: editor) }

    it "renders the news detail page" do
      login_as(editor)
      get admin_news_path(news_item)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/news/:id (update)" do
    let(:news_item) { create(:news_item, author: editor) }

    it "updates the news" do
      login_as(editor)
      patch admin_news_path(news_item), params: { news: { title_en: "Updated Title" } }
      expect(news_item.reload.title_en).to eq("Updated Title")
    end

    it "rejects invalid updates" do
      login_as(editor)
      patch admin_news_path(news_item), params: { news: { title_en: "", title_hi: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/news/:id/approve" do
    let(:news_item) { create(:news_item, :pending_review, author: co_editor) }

    it "allows editor to approve" do
      login_as(editor)
      patch approve_admin_news_path(news_item)
      expect(news_item.reload.status).to eq("approved")
    end

    it "denies co_editor from approving" do
      login_as(co_editor)
      patch approve_admin_news_path(news_item)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /admin/news/:id/reject" do
    let(:news_item) { create(:news_item, :pending_review, author: co_editor) }

    it "allows editor to reject with reason" do
      login_as(editor)
      patch reject_admin_news_path(news_item), params: { rejection_reason: "Needs revision" }
      expect(news_item.reload.status).to eq("rejected")
      expect(news_item.rejection_reason).to eq("Needs revision")
    end
  end

  describe "PATCH /admin/news/:id/submit_for_review" do
    let(:news_item) { create(:news_item, status: :draft, author: co_editor) }

    it "submits news for review" do
      login_as(co_editor)
      patch submit_for_review_admin_news_path(news_item)
      expect(news_item.reload.status).to eq("pending_review")
    end
  end

  describe "edit authorization" do
    let(:news_item) { create(:news_item, author: co_editor) }

    it "allows author (co_editor) to edit their own news" do
      login_as(co_editor)
      get edit_admin_news_path(news_item)
      expect(response).to have_http_status(:ok)
    end

    it "denies a different co_editor from editing" do
      other = create(:user, :co_editor)
      login_as(other)
      get edit_admin_news_path(news_item)
      expect(response).to redirect_to(root_path)
    end

    it "allows editor to edit any news" do
      login_as(editor)
      get edit_admin_news_path(news_item)
      expect(response).to have_http_status(:ok)
    end
  end
end
