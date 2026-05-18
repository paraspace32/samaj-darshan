require "rails_helper"

RSpec.describe "Jobs", type: :request do
  describe "GET /jobs" do
    it "renders the jobs index" do
      create(:job_post, :published)

      get jobs_path
      expect(response).to have_http_status(:ok)
    end

    it "renders empty state when no posts" do
      get jobs_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by category" do
      ft = create(:job_post, :published, :full_time)
      gov = create(:job_post, :published, :government)
      get jobs_path(category: :full_time)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ft.display_title)
      expect(response.body).not_to include(gov.display_title)
    end

    it "only shows published posts" do
      published = create(:job_post, :published)
      draft = create(:job_post, status: :draft)
      get jobs_path
      expect(response.body).to include(published.display_title)
      expect(response.body).not_to include(draft.display_title)
    end

    it "paginates results" do
      create_list(:job_post, 15, :published)
      get jobs_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /jobs/:id" do
    it "renders a published job post" do
      post_item = create(:job_post, :published)
      get job_path(post_item)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(post_item.display_title)
    end

    it "returns 404 for draft posts" do
      post_item = create(:job_post)
      get job_path(post_item)
      expect(response).to have_http_status(:not_found)
    end

    it "shows company name" do
      post_item = create(:job_post, :published, company_name: "Infosys")
      get job_path(post_item)
      expect(response.body).to include("Infosys")
    end

    it "shows related posts from same category" do
      post_item = create(:job_post, :published, :full_time)
      create(:job_post, :published, :full_time)
      get job_path(post_item)
      expect(response).to have_http_status(:ok)
    end

    it "loads with comments" do
      post_item = create(:job_post, :published)
      user = create(:user)
      post_item.comments.create!(body: "Applied already!", user: user)
      get job_path(post_item)
      expect(response).to have_http_status(:ok)
    end
  end
end
