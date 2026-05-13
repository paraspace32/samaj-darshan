require "rails_helper"

RSpec.describe "KanyadaanApplications", type: :request do
  # ── GET /kanyadaan/new ───────────────────────────────────────────────────────

  describe "GET /kanyadaan/new" do
    it "renders the application form" do
      get new_kanyadaan_application_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ── POST /kanyadaan ──────────────────────────────────────────────────────────

  describe "POST /kanyadaan" do
    let(:valid_params) do
      {
        kanyadaan_application: {
          girl_name: "Priya Sharma",
          parent_name: "Ramesh Sharma",
          contact: "9876543210",
          location: "Jaipur"
        }
      }
    end

    context "with valid params" do
      it "creates a new application" do
        expect {
          post kanyadaan_applications_path, params: valid_params
        }.to change(KanyadaanApplication, :count).by(1)
      end

      it "redirects to the success page" do
        post kanyadaan_applications_path, params: valid_params
        expect(response).to redirect_to(kanyadaan_success_path)
      end

      it "sets status to pending by default" do
        post kanyadaan_applications_path, params: valid_params
        expect(KanyadaanApplication.last.status).to eq("pending")
      end

      it "saves optional notes" do
        post kanyadaan_applications_path, params: {
          kanyadaan_application: valid_params[:kanyadaan_application].merge(notes: "Need urgent help")
        }
        expect(KanyadaanApplication.last.notes).to eq("Need urgent help")
      end
    end

    context "with invalid params" do
      it "does not create an application with missing girl_name" do
        expect {
          post kanyadaan_applications_path, params: {
            kanyadaan_application: valid_params[:kanyadaan_application].merge(girl_name: "")
          }
        }.not_to change(KanyadaanApplication, :count)
      end

      it "does not create an application with invalid contact" do
        expect {
          post kanyadaan_applications_path, params: {
            kanyadaan_application: valid_params[:kanyadaan_application].merge(contact: "12345")
          }
        }.not_to change(KanyadaanApplication, :count)
      end

      it "re-renders the form with errors" do
        post kanyadaan_applications_path, params: {
          kanyadaan_application: valid_params[:kanyadaan_application].merge(girl_name: "")
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── GET /kanyadaan/success ───────────────────────────────────────────────────

  describe "GET /kanyadaan/success" do
    it "renders the success page" do
      get kanyadaan_success_path
      expect(response).to have_http_status(:ok)
    end
  end
end
