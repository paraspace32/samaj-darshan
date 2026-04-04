require "rails_helper"

RSpec.describe "Webinars", type: :request do
  describe "GET /webinars" do
    it "renders the webinars index" do
      create(:webinar, :upcoming)
      create(:webinar, :past)

      get webinars_path
      expect(response).to have_http_status(:ok)
    end

    it "renders empty state when no webinars" do
      get webinars_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /webinars/:id" do
    it "renders a published webinar" do
      webinar = create(:webinar, :published)
      get webinar_path(webinar)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(webinar.display_title)
    end

    it "returns 404 for draft webinars" do
      webinar = create(:webinar)
      get webinar_path(webinar)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for cancelled webinars" do
      webinar = create(:webinar, :cancelled)
      get webinar_path(webinar)
      expect(response).to have_http_status(:not_found)
    end
  end
end
