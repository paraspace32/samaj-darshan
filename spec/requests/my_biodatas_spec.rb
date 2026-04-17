require "rails_helper"

RSpec.describe "MyBiodatas", type: :request do
  let(:user)  { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  # ── Auth guard ────────────────────────────────────────────────────────────

  describe "authentication" do
    it "redirects unauthenticated requests to login" do
      get my_biodatas_path
      expect(response).to redirect_to(login_path)
    end
  end

  # ── Index ─────────────────────────────────────────────────────────────────

  describe "GET /my_biodatas" do
    before { login_as(user) }

    it "returns 200 and lists the user's biodatas" do
      create(:biodata, user: user)
      get my_biodatas_path
      expect(response).to have_http_status(:ok)
    end

    it "does not show other users' biodatas" do
      other = create(:biodata, user: create(:user))
      get my_biodatas_path
      expect(response.body).not_to include(other.full_name)
    end
  end

  # ── New ───────────────────────────────────────────────────────────────────

  describe "GET /my_biodatas/new" do
    it "renders the form when logged in" do
      login_as(user)
      get new_my_biodata_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ── Create ────────────────────────────────────────────────────────────────

  describe "POST /my_biodatas" do
    before { login_as(user) }

    let(:valid_params) do
      {
        biodata: {
          full_name:     "Rahul Sharma",
          gender:        "male",
          date_of_birth: 28.years.ago.to_date.to_s,
          city:          "Indore",
          state:         "Madhya Pradesh",
          education:     "B.Tech"
        }
      }
    end

    it "creates a biodata and redirects to show" do
      expect {
        post my_biodatas_path, params: valid_params
      }.to change(Biodata, :count).by(1)
      expect(response).to redirect_to(my_biodata_path(Biodata.last))
    end

    it "sets status to draft by default" do
      post my_biodatas_path, params: valid_params
      expect(Biodata.last.status).to eq("draft")
    end

    it "associates the biodata with the current user" do
      post my_biodatas_path, params: valid_params
      expect(Biodata.last.user).to eq(user)
    end

    it "renders new with 422 on invalid params" do
      post my_biodatas_path, params: { biodata: { full_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts relatives_attributes" do
      params = valid_params.deep_merge(
        biodata: {
          relatives_attributes: {
            "0" => { relative_type: "Bhaiya", name: "Suresh" }
          }
        }
      )
      expect {
        post my_biodatas_path, params: params
      }.to change(Relative, :count).by(1)
    end
  end

  # ── Show ──────────────────────────────────────────────────────────────────

  describe "GET /my_biodatas/:id" do
    before { login_as(user) }

    it "renders the biodata" do
      biodata = create(:biodata, user: user)
      get my_biodata_path(biodata)
      expect(response).to have_http_status(:ok)
    end

    it "redirects when biodata belongs to another user" do
      other = create(:biodata, user: create(:user))
      get my_biodata_path(other)
      expect(response).to redirect_to(my_biodatas_path)
    end
  end

  # ── Edit / Update ─────────────────────────────────────────────────────────

  describe "GET /my_biodatas/:id/edit" do
    before { login_as(user) }

    it "renders the edit form" do
      biodata = create(:biodata, user: user)
      get edit_my_biodata_path(biodata)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /my_biodatas/:id" do
    before { login_as(user) }

    it "updates biodata and redirects to show" do
      biodata = create(:biodata, user: user)
      patch my_biodata_path(biodata), params: { biodata: { full_name: "Updated Name" } }
      expect(biodata.reload.full_name).to eq("Updated Name")
      expect(response).to redirect_to(my_biodata_path(biodata))
    end

    it "resets published biodata to draft after update" do
      biodata = create(:biodata, :published, user: user)
      patch my_biodata_path(biodata), params: { biodata: { full_name: "New Name" } }
      expect(biodata.reload.status).to eq("draft")
    end

    it "resets rejected biodata to draft after update" do
      biodata = create(:biodata, user: user, status: :rejected)
      patch my_biodata_path(biodata), params: { biodata: { full_name: "New Name" } }
      expect(biodata.reload.status).to eq("draft")
    end

    it "does not update another user's biodata" do
      other = create(:biodata, user: create(:user))
      patch my_biodata_path(other), params: { biodata: { full_name: "Hacked" } }
      expect(response).to redirect_to(my_biodatas_path)
      expect(other.reload.full_name).not_to eq("Hacked")
    end

    it "renders edit with 422 on invalid params" do
      biodata = create(:biodata, user: user)
      patch my_biodata_path(biodata), params: { biodata: { full_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "can destroy a relative via _destroy flag" do
      biodata  = create(:biodata, user: user)
      relative = create(:relative, biodata: biodata)
      patch my_biodata_path(biodata), params: {
        biodata: {
          full_name: biodata.full_name,
          relatives_attributes: { "0" => { id: relative.id, _destroy: "1" } }
        }
      }
      expect(Relative.exists?(relative.id)).to be false
    end
  end

  # ── Submit for review ─────────────────────────────────────────────────────

  describe "PATCH /my_biodatas/:id/submit_for_review" do
    before { login_as(user) }

    it "transitions status to pending_review" do
      biodata = create(:biodata, user: user)
      patch submit_for_review_my_biodata_path(biodata)
      expect(biodata.reload.status).to eq("pending_review")
      expect(response).to redirect_to(my_biodata_path(biodata))
    end

    it "does not allow acting on another user's biodata" do
      other = create(:biodata, user: create(:user))
      patch submit_for_review_my_biodata_path(other)
      expect(response).to redirect_to(my_biodatas_path)
    end
  end

  # ── Consent ───────────────────────────────────────────────────────────────

  describe "PATCH /my_biodatas/:id/consent" do
    let(:biodata) { create(:biodata, :pending_consent, user: user, created_by: admin) }

    before { login_as(user) }

    it "publishes the biodata" do
      patch consent_my_biodata_path(biodata)
      expect(biodata.reload.status).to eq("published")
      expect(response).to redirect_to(my_biodata_path(biodata))
    end

    it "stamps consented_at and sets user_consented" do
      freeze_time do
        patch consent_my_biodata_path(biodata)
        biodata.reload
        expect(biodata.user_consented).to be true
        expect(biodata.consented_at).to eq(Time.current)
      end
    end

    it "rejects when biodata is not pending_consent" do
      biodata.update_column(:status, Biodata.statuses[:draft])
      patch consent_my_biodata_path(biodata)
      expect(response).to redirect_to(my_biodata_path(biodata))
    end

    it "rejects when biodata was self-created (not admin-created)" do
      self_created = create(:biodata, :pending_consent, user: user)
      patch consent_my_biodata_path(self_created)
      expect(response).to redirect_to(my_biodata_path(self_created))
      expect(self_created.reload.status).not_to eq("published")
    end
  end

  # ── Decline consent ───────────────────────────────────────────────────────

  describe "PATCH /my_biodatas/:id/decline_consent" do
    let(:biodata) { create(:biodata, :pending_consent, user: user, created_by: admin) }

    before { login_as(user) }

    it "rejects the biodata with a reason" do
      patch decline_consent_my_biodata_path(biodata)
      biodata.reload
      expect(biodata.status).to eq("rejected")
      expect(biodata.rejection_reason).to eq("User declined consent")
      expect(response).to redirect_to(my_biodatas_path)
    end

    it "rejects when biodata is not pending_consent" do
      biodata.update_column(:status, Biodata.statuses[:draft])
      patch decline_consent_my_biodata_path(biodata)
      expect(response).to redirect_to(my_biodata_path(biodata))
      expect(biodata.reload.status).not_to eq("rejected")
    end
  end
end
