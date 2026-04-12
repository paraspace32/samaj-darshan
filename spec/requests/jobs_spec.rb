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
      create(:job_post, :published, :full_time)
      get jobs_path(category: :full_time)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /jobs/:id" do
    it "renders a published job post" do
      post = create(:job_post, :published)
      get job_path(post)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(post.display_title)
    end

    it "returns 404 for draft posts" do
      post = create(:job_post)
      get job_path(post)
      expect(response).to have_http_status(:not_found)
    end
  end
end
