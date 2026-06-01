require "rails_helper"

RSpec.describe "Biodatas WhatsApp Card", type: :request do
  let(:user)  { create(:user) }
  let(:owner) { create(:user) }

  # ── GET /biodatas/:id/whatsapp_card ──────────────────────────────────────

  describe "GET /biodatas/:id/whatsapp_card" do
    context "when not logged in" do
      it "redirects to login" do
        biodata = create(:biodata, :published, user: owner)
        get whatsapp_card_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      before { login_as(user) }

      it "returns JSON with card URL for a published biodata" do
        biodata = create(:biodata, :published, user: owner)

        # Stub the generator to avoid wkhtmltopdf dependency
        fake_attachment = biodata.whatsapp_card
        biodata.whatsapp_card.attach(
          io: StringIO.new("fake-jpeg"),
          filename: "card.jpg",
          content_type: "image/jpeg"
        )
        allow_any_instance_of(WhatsappCardGenerator).to receive(:generate).and_return(biodata.whatsapp_card)

        get whatsapp_card_biodata_path(biodata), as: :json
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["url"]).to be_present
      end

      it "returns 404 for non-published biodata" do
        draft = create(:biodata, user: owner)
        get whatsapp_card_biodata_path(draft), as: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for non-existent biodata" do
        get whatsapp_card_biodata_path(id: 999_999), as: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns 422 when generation fails" do
        biodata = create(:biodata, :published, user: owner)
        allow_any_instance_of(WhatsappCardGenerator).to receive(:generate)
          .and_raise(StandardError.new("PDF generation failed"))

        get whatsapp_card_biodata_path(biodata), as: :json
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("generation_failed")
      end
    end
  end

  # ── GET /biodatas/:id/download_card ──────────────────────────────────────

  describe "GET /biodatas/:id/download_card" do
    context "when not logged in" do
      it "redirects to login" do
        biodata = create(:biodata, :published, user: owner)
        get download_card_biodata_path(biodata)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in" do
      before { login_as(user) }

      it "redirects to the blob URL for download" do
        biodata = create(:biodata, :published, user: owner)
        biodata.whatsapp_card.attach(
          io: StringIO.new("fake-jpeg"),
          filename: "card.jpg",
          content_type: "image/jpeg"
        )
        allow_any_instance_of(WhatsappCardGenerator).to receive(:generate).and_return(biodata.whatsapp_card)

        get download_card_biodata_path(biodata)
        expect(response).to have_http_status(:redirect)
      end

      it "redirects to biodatas_path for non-published biodata" do
        draft = create(:biodata, user: owner)
        get download_card_biodata_path(draft)
        expect(response).to redirect_to(biodatas_path)
      end

      it "redirects to biodatas_path when generation fails" do
        biodata = create(:biodata, :published, user: owner)
        allow_any_instance_of(WhatsappCardGenerator).to receive(:generate)
          .and_raise(StandardError.new("Vips error"))

        get download_card_biodata_path(biodata)
        expect(response).to redirect_to(biodatas_path)
      end
    end
  end

  # ── Template includes WhatsApp button ────────────────────────────────────

  describe "GET /biodatas/:id/template (WhatsApp button)" do
    before { login_as(user) }

    it "renders the WhatsApp share button for published biodata" do
      biodata = create(:biodata, :published, user: owner)
      get template_biodata_path(biodata)
      expect(response.body).to include("share-card")
      expect(response.body).to include("WhatsApp")
      expect(response.body).to include(whatsapp_card_biodata_path(biodata))
    end
  end
end
