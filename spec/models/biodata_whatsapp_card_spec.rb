require "rails_helper"

RSpec.describe Biodata, "whatsapp_card", type: :model do
  describe "has_one_attached :whatsapp_card" do
    it "can attach a whatsapp card" do
      biodata = create(:biodata)
      biodata.whatsapp_card.attach(
        io: StringIO.new("fake-jpeg"),
        filename: "card.jpg",
        content_type: "image/jpeg"
      )
      expect(biodata.whatsapp_card).to be_attached
    end
  end

  describe "#purge_whatsapp_card_if_stale" do
    let(:biodata) { create(:biodata, :published) }

    before do
      biodata.whatsapp_card.attach(
        io: StringIO.new("fake-jpeg"),
        filename: "card.jpg",
        content_type: "image/jpeg"
      )
    end

    it "purges card when full_name changes" do
      expect(biodata.whatsapp_card).to be_attached
      biodata.update!(full_name: "New Name")
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when full_name_hi changes" do
      biodata.update!(full_name_hi: "नया नाम")
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when education changes" do
      biodata.update!(education: "PhD")
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when occupation changes" do
      biodata.update!(occupation: "Doctor")
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when city changes" do
      biodata.update!(city: "Mumbai")
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when state changes" do
      biodata.update!(state: "Maharashtra")
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when date_of_birth changes" do
      biodata.update!(date_of_birth: 25.years.ago.to_date)
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when height_cm changes" do
      biodata.update!(height_cm: 180)
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "purges card when caste changes" do
      biodata.update!(caste: "Agarwal")
      expect(biodata.reload.whatsapp_card).not_to be_attached
    end

    it "does NOT purge card when unrelated fields change" do
      biodata.update!(contact_phone: "9999999999")
      expect(biodata.reload.whatsapp_card).to be_attached
    end

    it "does NOT purge card when about_en changes" do
      biodata.update!(about_en: "Some new about text")
      expect(biodata.reload.whatsapp_card).to be_attached
    end

    it "does nothing when card is not attached" do
      biodata.whatsapp_card.purge
      expect {
        biodata.update!(full_name: "Changed Name")
      }.not_to raise_error
    end
  end
end
