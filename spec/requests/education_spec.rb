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
      board = create(:education_post, :published, :board_exam)
      comp = create(:education_post, :published, category: :competitive_exam)
      get education_index_path(category: :board_exam)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(board.display_title)
      expect(response.body).not_to include(comp.display_title)
    end

    it "only shows published posts" do
      published = create(:education_post, :published)
      draft = create(:education_post, status: :draft)
      get education_index_path
      expect(response.body).to include(published.display_title)
      expect(response.body).not_to include(draft.display_title)
    end

    it "paginates results" do
      create_list(:education_post, 15, :published)
      get education_index_path
      expect(response).to have_http_status(:ok)
    end

    it "handles page parameter" do
      create_list(:education_post, 15, :published)
      get education_index_path(page: 2)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /education/:id" do
    it "renders a published education post" do
      post_item = create(:education_post, :published)
      get education_path(post_item)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(post_item.display_title)
    end

    it "returns 404 for draft posts" do
      post_item = create(:education_post)
      get education_path(post_item)
      expect(response).to have_http_status(:not_found)
    end

    it "shows related posts from same category" do
      post_item = create(:education_post, :published, :board_exam)
      related = create(:education_post, :published, :board_exam)
      get education_path(post_item)
      expect(response).to have_http_status(:ok)
    end

    it "loads with comments" do
      post_item = create(:education_post, :published)
      user = create(:user)
      post_item.comments.create!(body: "Great resource!", user: user)
      get education_path(post_item)
      expect(response).to have_http_status(:ok)
    end
  end
end
