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

    it "separates upcoming and past webinars" do
      upcoming = create(:webinar, :upcoming)
      past = create(:webinar, :past)
      get webinars_path
      expect(response.body).to include(upcoming.display_title)
      expect(response.body).to include(past.display_title)
    end

    it "hides draft webinars" do
      draft = create(:webinar, status: :draft)
      get webinars_path
      expect(response.body).not_to include(draft.display_title)
    end

    it "hides cancelled webinars from upcoming" do
      cancelled = create(:webinar, :cancelled, starts_at: 3.days.from_now)
      get webinars_path
      expect(response.body).not_to include(cancelled.display_title)
    end
  end

  describe "GET /webinars/:id" do
    it "renders a published webinar" do
      webinar = create(:webinar, :published)
      get webinar_path(webinar)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(webinar.display_title)
    end

    it "shows speaker name" do
      webinar = create(:webinar, :published, speaker_name: "Dr. Meena Sharma")
      get webinar_path(webinar)
      expect(response.body).to include("Dr. Meena Sharma")
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

    context "upcoming webinar with Zoho registration" do
      it "shows registration iframe" do
        webinar = create(:webinar, :upcoming, :with_registration)
        get webinar_path(webinar)
        expect(response.body).to include("webinar.zoho.in/meeting/register/embed")
        expect(response.body).to include("<iframe")
      end
    end

    context "upcoming webinar with YouTube live URL" do
      it "shows YouTube embed" do
        webinar = create(:webinar, :upcoming, :with_youtube_live)
        get webinar_path(webinar)
        expect(response.body).to include("youtube.com/embed/abc123live")
      end
    end

    context "live webinar with Zoom link" do
      it "shows join button" do
        webinar = create(:webinar, :live, meeting_url: "https://zoom.us/j/999")
        get webinar_path(webinar)
        expect(response.body).to include("zoom.us/j/999")
      end
    end

    context "ended webinar with YouTube recording" do
      it "shows YouTube recording embed" do
        webinar = create(:webinar, :past_with_recording)
        get webinar_path(webinar)
        expect(response.body).to include("youtube.com/embed/recorded123")
      end
    end

    context "ended webinar without recording" do
      it "shows ended message" do
        webinar = create(:webinar, :past)
        get webinar_path(webinar)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
