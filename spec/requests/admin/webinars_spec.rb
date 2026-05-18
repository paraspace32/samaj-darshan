require "rails_helper"

RSpec.describe "Admin::Webinars", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor) { create(:user, :editor) }
  let(:regular_user) { create(:user) }

  describe "access control" do
    it "allows super_admin" do
      login_as(super_admin)
      get admin_webinars_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor with webinars section access" do
      login_as(editor)
      get admin_webinars_path
      expect(response).to have_http_status(:ok)
    end

    it "denies regular user" do
      login_as(regular_user)
      get admin_webinars_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/webinars" do
    before { login_as(super_admin) }

    it "lists webinars" do
      create(:webinar, :published)
      get admin_webinars_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      create(:webinar, :published)
      create(:webinar, :cancelled)
      get admin_webinars_path, params: { status: "published" }
      expect(response).to have_http_status(:ok)
    end

    it "searches by title and speaker" do
      create(:webinar, title_en: "AI in Education", speaker_name: "Dr. Sharma")
      get admin_webinars_path, params: { q: "AI" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AI")
    end
  end

  describe "POST /admin/webinars" do
    before { login_as(super_admin) }

    it "creates a new webinar" do
      expect {
        post admin_webinars_path, params: {
          webinar: {
            title_en: "New Webinar",
            description_en: "About community",
            speaker_name: "Dr. Sharma",
            platform: "zoom",
            starts_at: 2.days.from_now,
            duration_minutes: 60,
            meeting_url: "https://zoom.us/j/123"
          }
        }
      }.to change(Webinar, :count).by(1)
      expect(response).to redirect_to(admin_webinar_path(Webinar.last))
    end

    it "re-renders form on validation error" do
      post admin_webinars_path, params: {
        webinar: { title_en: "", speaker_name: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/webinars/:id" do
    let(:webinar) { create(:webinar, host: super_admin) }

    before { login_as(super_admin) }

    it "updates the webinar" do
      patch admin_webinar_path(webinar), params: {
        webinar: { title_en: "Updated Webinar" }
      }
      expect(webinar.reload.title_en).to eq("Updated Webinar")
      expect(response).to redirect_to(admin_webinar_path(webinar))
    end
  end

  describe "DELETE /admin/webinars/:id" do
    let!(:webinar) { create(:webinar, host: super_admin) }

    before { login_as(super_admin) }

    it "deletes the webinar" do
      expect {
        delete admin_webinar_path(webinar)
      }.to change(Webinar, :count).by(-1)
    end
  end

  describe "PATCH /admin/webinars/:id/publish" do
    let(:webinar) { create(:webinar, host: super_admin) }

    before { login_as(super_admin) }

    it "publishes the webinar" do
      patch publish_admin_webinar_path(webinar)
      expect(webinar.reload).to be_published
    end
  end

  describe "PATCH /admin/webinars/:id/cancel" do
    let(:webinar) { create(:webinar, :published, host: super_admin) }

    before { login_as(super_admin) }

    it "cancels the webinar" do
      patch cancel_admin_webinar_path(webinar)
      expect(webinar.reload).to be_cancelled
    end
  end
end
