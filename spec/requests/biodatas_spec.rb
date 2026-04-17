require "rails_helper"

RSpec.describe "Biodatas (public)", type: :request do
  let(:user)  { create(:user) }
  let(:owner) { create(:user) }

  # ── Index ─────────────────────────────────────────────────────────────────

  describe "GET /biodatas" do
    let!(:published_male)   { create(:biodata, :published, gender: :male,   city: "Indore", date_of_birth: 26.years.ago.to_date) }
    let!(:published_female) { create(:biodata, :published, :female,         city: "Bhopal", date_of_birth: 24.years.ago.to_date) }
    let!(:draft)            { create(:biodata, user: owner) }

    it "returns 200" do
      get biodatas_path
      expect(response).to have_http_status(:ok)
    end

    it "shows published biodatas and hides drafts" do
      get biodatas_path
      expect(response.body).to include(published_male.full_name)
      expect(response.body).to include(published_female.full_name)
      expect(response.body).not_to include(draft.full_name)
    end

    it "does not show pending_consent biodatas" do
      consent_bd = create(:biodata, :pending_consent, user: owner)
      get biodatas_path
      expect(response.body).not_to include(consent_bd.full_name)
    end

    it "filters by gender" do
      get biodatas_path, params: { gender: "male" }
      expect(response.body).to include(published_male.full_name)
      expect(response.body).not_to include(published_female.full_name)
    end

    it "filters by city (case-insensitive)" do
      get biodatas_path, params: { city: "indore" }
      expect(response.body).to include(published_male.full_name)
      expect(response.body).not_to include(published_female.full_name)
    end

    it "filters by age range" do
      get biodatas_path, params: { age_min: 25, age_max: 30 }
      expect(response.body).to include(published_male.full_name)
      expect(response.body).not_to include(published_female.full_name)
    end

    it "returns all published when no filters are given" do
      get biodatas_path
      expect(response.body).to include(published_male.full_name)
      expect(response.body).to include(published_female.full_name)
    end
  end

  # ── Show (redirects to template) ──────────────────────────────────────────

  describe "GET /biodatas/:id" do
    it "redirects to template path" do
      biodata = create(:biodata, :published, user: owner)
      login_as(user)
      get biodata_path(biodata)
      expect(response).to redirect_to(template_biodata_path(biodata))
    end
  end

  # ── Template ──────────────────────────────────────────────────────────────

  describe "GET /biodatas/:id/template" do
    context "when logged in" do
      before { login_as(user) }

      it "renders the biodata template for a published biodata" do
        biodata = create(:biodata, :published, user: owner)
        get template_biodata_path(biodata)
        expect(response).to have_http_status(:ok)
      end

      it "shows the full name" do
        biodata = create(:biodata, :published, user: owner, full_name: "Visible Person")
        get template_biodata_path(biodata)
        expect(response.body).to include("Visible Person")
      end

      it "redirects to biodatas_path for a non-published biodata" do
        draft = create(:biodata, user: owner)
        get template_biodata_path(draft)
        expect(response).to redirect_to(biodatas_path)
      end

      it "redirects when biodata does not exist" do
        get template_biodata_path(id: 999_999)
        expect(response).to redirect_to(biodatas_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        biodata = create(:biodata, :published, user: owner)
        get template_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  # ── Shortlist ─────────────────────────────────────────────────────────────

  describe "POST /biodatas/:id/shortlist" do
    context "when logged in" do
      before { login_as(user) }

      it "creates a shortlist entry for a published biodata" do
        biodata = create(:biodata, :published, user: owner)
        expect {
          post shortlist_biodata_path(biodata)
        }.to change(Shortlist, :count).by(1)
      end

      it "is idempotent — does not duplicate shortlist" do
        biodata = create(:biodata, :published, user: owner)
        create(:shortlist, user: user, biodata: biodata)
        expect {
          post shortlist_biodata_path(biodata)
        }.not_to change(Shortlist, :count)
      end

      it "redirects to the biodata template" do
        biodata = create(:biodata, :published, user: owner)
        post shortlist_biodata_path(biodata)
        expect(response).to redirect_to(template_biodata_path(biodata))
      end

      it "redirects to biodatas_path for non-published biodata" do
        draft = create(:biodata, user: owner)
        post shortlist_biodata_path(draft)
        expect(response).to redirect_to(biodatas_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        biodata = create(:biodata, :published, user: owner)
        post shortlist_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  # ── Unshortlist ───────────────────────────────────────────────────────────

  describe "DELETE /biodatas/:id/shortlist" do
    context "when logged in" do
      before { login_as(user) }

      it "removes an existing shortlist entry" do
        biodata = create(:biodata, :published, user: owner)
        create(:shortlist, user: user, biodata: biodata)
        expect {
          delete shortlist_biodata_path(biodata)
        }.to change(Shortlist, :count).by(-1)
      end

      it "is idempotent — no error when not shortlisted" do
        biodata = create(:biodata, :published, user: owner)
        expect {
          delete shortlist_biodata_path(biodata)
        }.not_to raise_error
        expect(response).to redirect_to(template_biodata_path(biodata))
      end

      it "does not remove another user's shortlist" do
        biodata    = create(:biodata, :published, user: owner)
        other_user = create(:user)
        create(:shortlist, user: other_user, biodata: biodata)
        delete shortlist_biodata_path(biodata)
        expect(Shortlist.exists?(user: other_user, biodata: biodata)).to be true
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        biodata = create(:biodata, :published, user: owner)
        delete shortlist_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
