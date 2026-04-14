require "rails_helper"

RSpec.describe "Education", type: :request do
  describe "GET /education" do
    it "renders the education index" do
      create(:education_post, :published)

      get education_index_path
      expect(response).to have_http_status(:ok)
    end

    it "renders empty state when no posts" do
      get education_index_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by category" do
      create(:education_post, :published, :board_exam)
      get education_index_path(category: :board_exam)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /education/:id" do
    it "renders a published education post" do
      post = create(:education_post, :published)
      get education_path(post)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(post.display_title)
    end

    it "returns 404 for draft posts" do
      post = create(:education_post)
      get education_path(post)
      expect(response).to have_http_status(:not_found)
    end
  end
end
