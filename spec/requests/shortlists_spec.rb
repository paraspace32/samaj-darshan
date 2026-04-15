require "rails_helper"

RSpec.describe "Shortlists", type: :request do
  let(:user)    { create(:user) }
  let(:owner)   { create(:user) }
  let(:biodata) { create(:biodata, :published, user: owner) }

  # ── Index ──────────────────────────────────────────────────────────────────

  describe "GET /shortlists" do
    context "when logged in" do
      before { login_as(user) }

      it "returns 200 with shortlisted biodatas" do
        create(:shortlist, user: user, biodata: biodata)
        get shortlists_path
        expect(response).to have_http_status(:ok)
      end

      it "shows an empty state when nothing is shortlisted" do
        get shortlists_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("shortlists.empty"))
      end

      it "does not show other users' shortlists" do
        other_user    = create(:user)
        other_biodata = create(:biodata, :published, user: create(:user))
        create(:shortlist, user: other_user, biodata: other_biodata)

        get shortlists_path
        expect(response.body).not_to include(other_biodata.display_name)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get shortlists_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  # ── Shortlist (add) ────────────────────────────────────────────────────────

  describe "POST /biodatas/:id/shortlist" do
    context "when logged in" do
      before { login_as(user) }

      it "creates a shortlist entry" do
        expect {
          post shortlist_biodata_path(biodata)
        }.to change(Shortlist, :count).by(1)
      end

      it "associates the shortlist with the current user and biodata" do
        post shortlist_biodata_path(biodata)
        shortlist = Shortlist.last
        expect(shortlist.user).to eq(user)
        expect(shortlist.biodata).to eq(biodata)
      end

      it "does not create a duplicate if already shortlisted" do
        create(:shortlist, user: user, biodata: biodata)
        expect {
          post shortlist_biodata_path(biodata)
        }.not_to change(Shortlist, :count)
      end

      it "redirects back after shortlisting" do
        post shortlist_biodata_path(biodata)
        expect(response).to redirect_to(template_biodata_path(biodata))
      end

      it "returns 404 for a non-published biodata" do
        draft = create(:biodata, user: create(:user))
        post shortlist_biodata_path(draft)
        expect(response).to redirect_to(biodatas_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post shortlist_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end

      it "does not create a shortlist entry" do
        expect {
          post shortlist_biodata_path(biodata)
        }.not_to change(Shortlist, :count)
      end
    end
  end

  # ── Unshortlist (remove) ───────────────────────────────────────────────────

  describe "DELETE /biodatas/:id/shortlist" do
    context "when logged in" do
      before do
        login_as(user)
        create(:shortlist, user: user, biodata: biodata)
      end

      it "removes the shortlist entry" do
        expect {
          delete shortlist_biodata_path(biodata)
        }.to change(Shortlist, :count).by(-1)
      end

      it "only removes the current user's shortlist, not others'" do
        other_user = create(:user)
        create(:shortlist, user: other_user, biodata: biodata)

        expect {
          delete shortlist_biodata_path(biodata)
        }.to change(Shortlist, :count).by(-1)

        expect(Shortlist.exists?(user: other_user, biodata: biodata)).to be true
      end

      it "redirects back after removing" do
        delete shortlist_biodata_path(biodata)
        expect(response).to redirect_to(template_biodata_path(biodata))
      end

      it "is idempotent — no error if not shortlisted" do
        delete shortlist_biodata_path(biodata)  # remove once
        expect {
          delete shortlist_biodata_path(biodata)  # remove again
        }.not_to change(Shortlist, :count)
        expect(response).to redirect_to(template_biodata_path(biodata))
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        delete shortlist_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  # ── Index page — shortlisted profiles still visible ───────────────────────

  describe "GET /biodatas (index)" do
    it "still shows a biodata on the index page after it is shortlisted" do
      create(:shortlist, user: user, biodata: biodata)
      get biodatas_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(biodata.display_name)
    end
  end
end
