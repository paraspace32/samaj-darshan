require "rails_helper"

RSpec.describe "MyBiodatas WhatsApp Card", type: :request do
  let(:user) { create(:user) }

  # ── GET /my_biodatas/:id/whatsapp_card ───────────────────────────────────

  describe "GET /my_biodatas/:id/whatsapp_card" do
    context "when not logged in" do
      it "redirects to login" do
        biodata = create(:biodata, :published, user: user)
        get whatsapp_card_my_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      before { login_as(user) }

      it "returns JSON with card URL for own published biodata" do
        biodata = create(:biodata, :published, user: user)
        biodata.whatsapp_card.attach(
          io: StringIO.new("fake-jpeg"),
          filename: "card.jpg",
          content_type: "image/jpeg"
        )
        allow_any_instance_of(WhatsappCardGenerator).to receive(:generate).and_return(biodata.whatsapp_card)

        get whatsapp_card_my_biodata_path(biodata), as: :json
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["url"]).to be_present
      end

      it "returns 422 for own non-published (draft) biodata" do
        draft = create(:biodata, user: user, status: :draft)
        get whatsapp_card_my_biodata_path(draft), as: :json
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("not_published")
      end

      it "redirects when biodata belongs to another user" do
        other = create(:biodata, :published, user: create(:user))
        get whatsapp_card_my_biodata_path(other), as: :json
        expect(response).to redirect_to(my_biodatas_path)
      end

      it "returns 422 when generation fails" do
        biodata = create(:biodata, :published, user: user)
        allow_any_instance_of(WhatsappCardGenerator).to receive(:generate)
          .and_raise(StandardError.new("generation error"))

        get whatsapp_card_my_biodata_path(biodata), as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── GET /my_biodatas/:id/download_card ───────────────────────────────────

  describe "GET /my_biodatas/:id/download_card" do
    context "when logged in" do
      before { login_as(user) }

      it "redirects to blob URL for download" do
        biodata = create(:biodata, :published, user: user)
        biodata.whatsapp_card.attach(
          io: StringIO.new("fake-jpeg"),
          filename: "card.jpg",
          content_type: "image/jpeg"
        )
        allow_any_instance_of(WhatsappCardGenerator).to receive(:generate).and_return(biodata.whatsapp_card)

        get download_card_my_biodata_path(biodata)
        expect(response).to have_http_status(:redirect)
      end

      it "redirects back for non-published biodata" do
        draft = create(:biodata, user: user, status: :draft)
        get download_card_my_biodata_path(draft)
        expect(response).to redirect_to(my_biodata_path(draft))
      end

      it "redirects when biodata belongs to another user" do
        other = create(:biodata, :published, user: create(:user))
        get download_card_my_biodata_path(other)
        expect(response).to redirect_to(my_biodatas_path)
      end
    end
  end

  # ── Template shows WhatsApp button only for published ────────────────────

  describe "GET /my_biodatas/:id/template" do
    before { login_as(user) }

    it "shows WhatsApp button for published biodata" do
      biodata = create(:biodata, :published, user: user)
      get template_my_biodata_path(biodata)
      expect(response.body).to include("share-card")
      expect(response.body).to include("WhatsApp")
    end

    it "does NOT show WhatsApp button for draft biodata" do
      draft = create(:biodata, user: user, status: :draft)
      get template_my_biodata_path(draft)
      expect(response.body).not_to include("share-card")
    end
  end
end
