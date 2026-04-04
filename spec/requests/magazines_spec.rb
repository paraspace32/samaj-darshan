require "rails_helper"

RSpec.describe "Magazines", type: :request do
  describe "GET /magazines" do
    it "renders published magazines" do
      create(:magazine, :published)
      get magazines_path
      expect(response).to have_http_status(:ok)
    end

    it "does not show draft magazines" do
      draft = create(:magazine, status: :draft)
      pub = create(:magazine, :published)
      get magazines_path
      expect(response.body).to include(pub.display_title)
      expect(response.body).not_to include(draft.display_title)
    end

    it "renders empty state when no magazines" do
      get magazines_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /magazines/:id" do
    let(:magazine) { create(:magazine, :published) }

    it "renders the magazine issue" do
      create(:magazine_article, magazine: magazine)
      get magazine_path(magazine)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(magazine.display_title)
    end

    it "returns 404 for draft magazines" do
      draft = create(:magazine, status: :draft)
      get magazine_path(draft)
      expect(response).to have_http_status(:not_found)
    end
  end
end
