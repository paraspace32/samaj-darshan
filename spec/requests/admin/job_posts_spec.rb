require "rails_helper"

RSpec.describe "Admin::JobPosts", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:regular_user) { create(:user) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_job_posts_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor with jobs section access" do
      login_as(editor)
      get admin_job_posts_path
      expect(response).to have_http_status(:ok)
    end

    it "denies regular user" do
      login_as(regular_user)
      get admin_job_posts_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/job_posts" do
    before { login_as(super_admin) }

    it "lists job posts" do
      create(:job_post, :published)
      get admin_job_posts_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      create(:job_post, :published)
      get admin_job_posts_path, params: { status: "published" }
      expect(response).to have_http_status(:ok)
    end

    it "filters by category" do
      create(:job_post, :published, :government)
      get admin_job_posts_path, params: { category: "government" }
      expect(response).to have_http_status(:ok)
    end

    it "searches by title and company" do
      create(:job_post, title_en: "TCS Hiring", company_name: "TCS")
      get admin_job_posts_path, params: { q: "TCS" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TCS")
    end
  end

  describe "POST /admin/job_posts" do
    before { login_as(super_admin) }

    it "creates a new job post" do
      expect {
        post admin_job_posts_path, params: {
          job_post: {
            title_en: "Software Engineer",
            description_en: "Build cool stuff",
            category: "full_time",
            company_name: "Acme Corp"
          }
        }
      }.to change(JobPost, :count).by(1)
      expect(response).to redirect_to(admin_job_post_path(JobPost.last))
    end

    it "re-renders form on validation error" do
      post admin_job_posts_path, params: {
        job_post: { title_en: "", description_en: "", company_name: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/job_posts/:id" do
    let(:job) { create(:job_post, author: super_admin) }

    before { login_as(super_admin) }

    it "updates the post" do
      patch admin_job_post_path(job), params: {
        job_post: { title_en: "Updated Job" }
      }
      expect(job.reload.title_en).to eq("Updated Job")
      expect(response).to redirect_to(admin_job_post_path(job))
    end
  end

  describe "DELETE /admin/job_posts/:id" do
    let!(:job) { create(:job_post, author: super_admin) }

    before { login_as(super_admin) }

    it "deletes the post" do
      expect {
        delete admin_job_post_path(job)
      }.to change(JobPost, :count).by(-1)
    end
  end

  describe "PATCH /admin/job_posts/:id/publish" do
    let(:job) { create(:job_post, author: super_admin) }

    before { login_as(super_admin) }

    it "publishes the post" do
      patch publish_admin_job_post_path(job)
      expect(job.reload).to be_published
    end
  end
end
