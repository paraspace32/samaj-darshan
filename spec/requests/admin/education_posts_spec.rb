require "rails_helper"

RSpec.describe "Admin::EducationPosts", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:regular_user) { create(:user) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_education_posts_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor with education section access" do
      login_as(editor)
      get admin_education_posts_path
      expect(response).to have_http_status(:ok)
    end

    it "denies regular user" do
      login_as(regular_user)
      get admin_education_posts_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/education_posts" do
    before { login_as(super_admin) }

    it "lists education posts" do
      create(:education_post, :published)
      get admin_education_posts_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      create(:education_post, :published)
      create(:education_post, status: :draft)
      get admin_education_posts_path, params: { status: "published" }
      expect(response).to have_http_status(:ok)
    end

    it "filters by category" do
      create(:education_post, :published, :board_exam)
      get admin_education_posts_path, params: { category: "board_exam" }
      expect(response).to have_http_status(:ok)
    end

    it "searches by title" do
      create(:education_post, title_en: "UPSC Prelims 2026")
      get admin_education_posts_path, params: { q: "UPSC" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("UPSC")
    end
  end

  describe "POST /admin/education_posts" do
    before { login_as(super_admin) }

    it "creates a new education post" do
      expect {
        post admin_education_posts_path, params: {
          education_post: {
            title_en: "New Exam Alert",
            content_en: "Details about the exam",
            category: "competitive_exam",
            organization_name: "UPSC"
          }
        }
      }.to change(EducationPost, :count).by(1)
      expect(response).to redirect_to(admin_education_post_path(EducationPost.last))
    end

    it "re-renders form on validation error" do
      post admin_education_posts_path, params: {
        education_post: { title_en: "", content_en: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/education_posts/:id" do
    let(:post_item) { create(:education_post, author: super_admin) }

    before { login_as(super_admin) }

    it "updates the post" do
      patch admin_education_post_path(post_item), params: {
        education_post: { title_en: "Updated Title" }
      }
      expect(post_item.reload.title_en).to eq("Updated Title")
      expect(response).to redirect_to(admin_education_post_path(post_item))
    end
  end

  describe "DELETE /admin/education_posts/:id" do
    let!(:post_item) { create(:education_post, author: super_admin) }

    before { login_as(super_admin) }

    it "deletes the post" do
      expect {
        delete admin_education_post_path(post_item)
      }.to change(EducationPost, :count).by(-1)
      expect(response).to redirect_to(admin_education_posts_path)
    end
  end

  describe "PATCH /admin/education_posts/:id/publish" do
    let(:post_item) { create(:education_post, author: super_admin) }

    before { login_as(super_admin) }

    it "publishes the post" do
      patch publish_admin_education_post_path(post_item)
      expect(post_item.reload).to be_published
    end
  end
end
