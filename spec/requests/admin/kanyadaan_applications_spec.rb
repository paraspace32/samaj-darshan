require "rails_helper"

RSpec.describe "Admin::KanyadaanApplications", type: :request do
  let(:super_admin)      { create(:user, :super_admin) }
  let(:female_president) { create(:user, :female_president) }
  let(:editor)           { create(:user, :editor) }
  let(:regular)          { create(:user) }

  # ── Access control ────────────────────────────────────────────────────────

  describe "access control" do
    it "allows super_admin to access index" do
      login_as(super_admin)
      get admin_kanyadaan_applications_path
      expect(response).to have_http_status(:ok)
    end

    it "allows female_president to access index" do
      login_as(female_president)
      get admin_kanyadaan_applications_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor with kanyadaan section access" do
      login_as(editor)
      get admin_kanyadaan_applications_path
      expect(response).to have_http_status(:ok)
    end

    it "denies editor without kanyadaan section access" do
      editor_no_kanyadaan = create(:user, :editor, allowed_sections: %w[news])
      login_as(editor_no_kanyadaan)
      get admin_kanyadaan_applications_path
      expect(response).to redirect_to(root_path)
    end

    it "denies regular user access to index" do
      login_as(regular)
      get admin_kanyadaan_applications_path
      expect(response).to redirect_to(root_path)
    end

    it "denies unauthenticated access" do
      get admin_kanyadaan_applications_path
      expect(response).to redirect_to(login_path)
    end
  end

  # ── Index ─────────────────────────────────────────────────────────────────

  describe "GET /admin/kanyadaan_applications" do
    before { login_as(super_admin) }

    it "lists all applications newest first" do
      old_app = create(:kanyadaan_application, created_at: 2.days.ago)
      new_app = create(:kanyadaan_application, created_at: 1.hour.ago)

      get admin_kanyadaan_applications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(new_app.girl_name)
      expect(response.body).to include(old_app.girl_name)
    end

    it "filters by status" do
      pending_app  = create(:kanyadaan_application, status: :pending)
      approved_app = create(:kanyadaan_application, status: :approved)

      get admin_kanyadaan_applications_path(status: "approved")
      expect(response.body).to include(approved_app.girl_name)
      expect(response.body).not_to include(pending_app.girl_name)
    end
  end

  # ── Show ──────────────────────────────────────────────────────────────────

  describe "GET /admin/kanyadaan_applications/:id" do
    let(:application) { create(:kanyadaan_application, :with_notes) }

    before { login_as(female_president) }

    it "shows application details" do
      get admin_kanyadaan_application_path(application)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ERB::Util.html_escape(application.girl_name))
      expect(response.body).to include(ERB::Util.html_escape(application.parent_name))
      expect(response.body).to include(application.contact)
      expect(response.body).to include(ERB::Util.html_escape(application.location))
    end
  end

  # ── Update ────────────────────────────────────────────────────────────────

  describe "PATCH /admin/kanyadaan_applications/:id" do
    let(:application) { create(:kanyadaan_application) }

    before { login_as(super_admin) }

    it "updates the status" do
      patch admin_kanyadaan_application_path(application), params: {
        kanyadaan_application: { status: "approved" }
      }
      expect(application.reload.status).to eq("approved")
      expect(response).to redirect_to(admin_kanyadaan_application_path(application))
    end

    it "updates admin notes" do
      patch admin_kanyadaan_application_path(application), params: {
        kanyadaan_application: { notes: "Verified documents" }
      }
      expect(application.reload.notes).to eq("Verified documents")
    end

    it "does not allow updating girl_name (unpermitted)" do
      patch admin_kanyadaan_application_path(application), params: {
        kanyadaan_application: { girl_name: "Hacked Name" }
      }
      expect(application.reload.girl_name).not_to eq("Hacked Name")
    end
  end
end
