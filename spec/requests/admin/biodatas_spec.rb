require "rails_helper"

RSpec.describe "Admin::Biodatas", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:editor)      { create(:user, :editor) }
  let(:moderator)   { create(:user, :moderator) }
  let(:regular)     { create(:user) }

  # ── Access control ────────────────────────────────────────────────────────

  describe "access control" do
    it "allows super_admin to access index" do
      login_as(super_admin)
      get admin_biodatas_path
      expect(response).to have_http_status(:ok)
    end

    it "allows editor to access index" do
      login_as(editor)
      get admin_biodatas_path
      expect(response).to have_http_status(:ok)
    end

    it "allows moderator to access index" do
      login_as(moderator)
      get admin_biodatas_path
      expect(response).to have_http_status(:ok)
    end

    it "denies regular user access to index" do
      login_as(regular)
      get admin_biodatas_path
      expect(response).to redirect_to(root_path)
    end

    it "denies unauthenticated access" do
      get admin_biodatas_path
      expect(response).to redirect_to(login_path)
    end

    it "allows editor to access new form" do
      login_as(editor)
      get new_admin_biodata_path
      expect(response).to have_http_status(:ok)
    end

    it "denies moderator from new form (reviewer, not manager)" do
      login_as(moderator)
      get new_admin_biodata_path
      expect(response).to redirect_to(root_path)
    end
  end

  # ── Index ─────────────────────────────────────────────────────────────────

  describe "GET /admin/biodatas" do
    before { login_as(super_admin) }

    it "returns all biodatas ordered by created_at desc" do
      old_bd = create(:biodata, created_at: 2.days.ago)
      new_bd = create(:biodata, created_at: 1.day.ago)
      get admin_biodatas_path
      expect(response.body.index(new_bd.full_name)).to be < response.body.index(old_bd.full_name)
    end

    it "filters by status param" do
      published = create(:biodata, :published)
      draft     = create(:biodata)
      get admin_biodatas_path, params: { status: "published" }
      expect(response.body).to include(published.full_name)
      expect(response.body).not_to include(draft.full_name)
    end

    it "filters pending_consent biodatas" do
      consent_bd = create(:biodata, :pending_consent)
      get admin_biodatas_path, params: { status: "pending_consent" }
      expect(response.body).to include(consent_bd.full_name)
    end

    it "filters by gender param" do
      male   = create(:biodata, gender: :male)
      female = create(:biodata, :female)
      get admin_biodatas_path, params: { gender: "male" }
      expect(response.body).to include(male.full_name)
      expect(response.body).not_to include(female.full_name)
    end

    it "searches by name" do
      target = create(:biodata, full_name: "Unique Searchable Name")
      other  = create(:biodata, full_name: "Other Person")
      get admin_biodatas_path, params: { q: "Unique" }
      expect(response.body).to include("Unique Searchable Name")
      expect(response.body).not_to include("Other Person")
    end
  end

  # ── Show ──────────────────────────────────────────────────────────────────

  describe "GET /admin/biodatas/:id" do
    before { login_as(super_admin) }

    it "renders the biodata detail page" do
      biodata = create(:biodata)
      get admin_biodata_path(biodata)
      expect(response).to have_http_status(:ok)
    end

    it "shows created_by info for admin-created biodatas" do
      target_user = create(:user)
      biodata     = create(:biodata, :pending_consent, user: target_user, created_by: super_admin)
      get admin_biodata_path(biodata)
      expect(response).to have_http_status(:ok)
    end
  end

  # ── New / Create ──────────────────────────────────────────────────────────

  describe "GET /admin/biodatas/new" do
    before { login_as(editor) }

    it "renders new form" do
      get new_admin_biodata_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/biodatas" do
    before { login_as(super_admin) }

    let(:target_user) { create(:user) }
    let(:valid_params) do
      {
        biodata: {
          user_id:       target_user.id,
          full_name:     "Admin Created",
          gender:        "male",
          date_of_birth: 30.years.ago.to_date.to_s,
          city:          "Bhopal",
          state:         "Madhya Pradesh",
          education:     "MBA"
        }
      }
    end

    it "creates a biodata with pending_consent status" do
      expect {
        post admin_biodatas_path, params: valid_params
      }.to change(Biodata, :count).by(1)
      expect(Biodata.last.status).to eq("pending_consent")
    end

    it "sets created_by_id to the current admin" do
      post admin_biodatas_path, params: valid_params
      expect(Biodata.last.created_by_id).to eq(super_admin.id)
    end

    it "associates biodata with the selected user" do
      post admin_biodatas_path, params: valid_params
      expect(Biodata.last.user).to eq(target_user)
    end

    it "redirects to the new biodata show page" do
      post admin_biodatas_path, params: valid_params
      expect(response).to redirect_to(admin_biodata_path(Biodata.last))
    end

    it "renders new with 422 when user_id is blank" do
      post admin_biodatas_path, params: {
        biodata: valid_params[:biodata].merge(user_id: "")
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "renders new with 422 when biodata is invalid" do
      post admin_biodatas_path, params: {
        biodata: { user_id: target_user.id, full_name: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "accepts relatives_attributes" do
      params = valid_params.deep_merge(
        biodata: {
          relatives_attributes: {
            "0" => { relative_type: "Mama", name: "Dinesh" }
          }
        }
      )
      expect {
        post admin_biodatas_path, params: params
      }.to change(Relative, :count).by(1)
    end
  end

  # ── Edit / Update ─────────────────────────────────────────────────────────

  describe "GET /admin/biodatas/:id/edit" do
    before { login_as(editor) }

    it "renders the edit form" do
      biodata = create(:biodata)
      get edit_admin_biodata_path(biodata)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/biodatas/:id" do
    before { login_as(super_admin) }

    it "updates the biodata and redirects to show" do
      biodata = create(:biodata)
      patch admin_biodata_path(biodata), params: { biodata: { full_name: "Updated Admin Name" } }
      expect(biodata.reload.full_name).to eq("Updated Admin Name")
      expect(response).to redirect_to(admin_biodata_path(biodata))
    end

    it "renders edit with 422 on invalid params" do
      biodata = create(:biodata)
      patch admin_biodata_path(biodata), params: { biodata: { full_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "can update relatives via nested attributes" do
      biodata  = create(:biodata)
      relative = create(:relative, biodata: biodata)
      patch admin_biodata_path(biodata), params: {
        biodata: {
          full_name:            biodata.full_name,
          relatives_attributes: { "0" => { id: relative.id, name: "New Name" } }
        }
      }
      expect(relative.reload.name).to eq("New Name")
    end
  end

  # ── Publish ───────────────────────────────────────────────────────────────

  describe "PATCH /admin/biodatas/:id/publish" do
    context "as super_admin" do
      before { login_as(super_admin) }

      it "publishes a pending_review biodata" do
        biodata = create(:biodata, status: :pending_review)
        patch publish_admin_biodata_path(biodata)
        expect(biodata.reload.status).to eq("published")
        expect(response).to redirect_to(admin_biodata_path(biodata))
      end

      it "stamps published_at" do
        biodata = create(:biodata, status: :pending_review)
        freeze_time do
          patch publish_admin_biodata_path(biodata)
          expect(biodata.reload.published_at).to eq(Time.current)
        end
      end
    end

    context "as moderator" do
      before { login_as(moderator) }

      it "denies moderator from publishing" do
        biodata = create(:biodata, status: :pending_review)
        patch publish_admin_biodata_path(biodata)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ── Reject ────────────────────────────────────────────────────────────────

  describe "PATCH /admin/biodatas/:id/reject" do
    before { login_as(super_admin) }

    it "rejects a biodata with a reason" do
      biodata = create(:biodata, status: :pending_review)
      patch reject_admin_biodata_path(biodata), params: { rejection_reason: "Incomplete data" }
      biodata.reload
      expect(biodata.status).to eq("rejected")
      expect(biodata.rejection_reason).to eq("Incomplete data")
      expect(response).to redirect_to(admin_biodatas_path)
    end
  end

  # ── Destroy ───────────────────────────────────────────────────────────────

  describe "DELETE /admin/biodatas/:id" do
    it "destroys the biodata (super_admin only)" do
      biodata = create(:biodata)
      login_as(super_admin)
      expect {
        delete admin_biodata_path(biodata)
      }.to change(Biodata, :count).by(-1)
      expect(response).to redirect_to(admin_biodatas_path)
    end

    it "denies editor from destroying" do
      biodata = create(:biodata)
      login_as(editor)
      expect {
        delete admin_biodata_path(biodata)
      }.not_to change(Biodata, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  # ── Search users ──────────────────────────────────────────────────────────

  describe "GET /admin/biodatas/search_users" do
    before { login_as(editor) }

    it "returns matching users as JSON" do
      target = create(:user, name: "Rajesh Kumar", phone: "9000000001")
      get search_users_admin_biodatas_path, params: { q: "Rajesh" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.map { |u| u["id"] }).to include(target.id)
    end

    it "returns up to 15 users when query is blank" do
      create_list(:user, 5)
      get search_users_admin_biodatas_path, params: { q: "" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to be <= 15
    end

    it "returns id and label for each user" do
      create(:user, name: "Test User", phone: "9111000001")
      get search_users_admin_biodatas_path, params: { q: "Test" }
      json = JSON.parse(response.body)
      expect(json.first.keys).to include("id", "label")
    end
  end
end
