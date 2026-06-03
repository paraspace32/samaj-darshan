require "rails_helper"

RSpec.describe WhatsappCardGenerator do
  let(:biodata) { create(:biodata, :published, full_name: "Rahul Sharma", full_name_hi: "राहुल शर्मा") }

  describe "#generate" do
    context "when whatsapp_card is already attached with current version" do
      before do
        biodata.whatsapp_card.attach(
          io: StringIO.new("fake-jpeg-data"),
          filename: "biodata_card_#{biodata.id}_v#{WhatsappCardGenerator::TEMPLATE_VERSION}.jpg",
          content_type: "image/jpeg"
        )
      end

      it "returns the existing attachment without regenerating" do
        generator = described_class.new
        expect(generator).not_to receive(:render_pdf)
        result = generator.generate(biodata)
        expect(result).to be_attached
      end
    end

    context "when whatsapp_card is attached with an old version" do
      before do
        biodata.whatsapp_card.attach(
          io: StringIO.new("fake-jpeg-data"),
          filename: "biodata_card_#{biodata.id}_v1.jpg",
          content_type: "image/jpeg"
        )
      end

      it "purges old card and regenerates" do
        generator = described_class.new
        fake_pdf = "fake-pdf-binary"
        fake_jpeg = "fake-jpeg-binary"
        allow(generator).to receive(:render_pdf).with(biodata).and_return(fake_pdf)
        allow(generator).to receive(:pdf_to_jpeg).with(fake_pdf).and_return(fake_jpeg)

        result = generator.generate(biodata)
        expect(result).to be_attached
        expect(result.blob.filename.to_s).to include("_v#{WhatsappCardGenerator::TEMPLATE_VERSION}")
      end
    end

    context "when whatsapp_card is not attached" do
      it "calls render_pdf and pdf_to_jpeg" do
        generator = described_class.new
        fake_pdf = "fake-pdf-binary"
        fake_jpeg = "fake-jpeg-binary"

        allow(generator).to receive(:render_pdf).with(biodata).and_return(fake_pdf)
        allow(generator).to receive(:pdf_to_jpeg).with(fake_pdf).and_return(fake_jpeg)

        result = generator.generate(biodata)

        expect(result).to be_attached
        expect(result.blob.content_type).to eq("image/jpeg")
        expect(result.blob.filename.to_s).to eq(
          "biodata_card_#{biodata.id}_v#{WhatsappCardGenerator::TEMPLATE_VERSION}.jpg"
        )
      end
    end
  end

  describe "#render_pdf (private)" do
    it "renders the whatsapp_card template as HTML" do
      generator = described_class.new

      fake_pdf = "fake-pdf-output"
      wicked_instance = instance_double(WickedPdf)
      allow(WickedPdf).to receive(:new).and_return(wicked_instance)
      allow(wicked_instance).to receive(:pdf_from_string).and_return(fake_pdf)

      result = generator.send(:render_pdf, biodata)

      expect(result).to eq(fake_pdf)
      expect(wicked_instance).to have_received(:pdf_from_string).with(
        a_string_including("Rahul Sharma"),
        hash_including(
          margin: { top: 0, bottom: 0, left: 0, right: 0 },
          disable_smart_shrinking: true
        )
      )
    end

    it "includes the Hindi name in the rendered HTML" do
      generator = described_class.new

      wicked_instance = instance_double(WickedPdf)
      allow(WickedPdf).to receive(:new).and_return(wicked_instance)
      allow(wicked_instance).to receive(:pdf_from_string).and_return("pdf")

      generator.send(:render_pdf, biodata)

      expect(wicked_instance).to have_received(:pdf_from_string).with(
        a_string_including("राहुल शर्मा"),
        anything
      )
    end

    it "embeds photo as data URI when photo is attached" do
      biodata.photo.attach(
        io: StringIO.new("fake-image-bytes"),
        filename: "photo.jpg",
        content_type: "image/jpeg"
      )

      generator = described_class.new
      wicked_instance = instance_double(WickedPdf)
      allow(WickedPdf).to receive(:new).and_return(wicked_instance)
      allow(wicked_instance).to receive(:pdf_from_string).and_return("pdf")

      generator.send(:render_pdf, biodata)

      expect(wicked_instance).to have_received(:pdf_from_string).with(
        a_string_including("data:image/jpeg;base64,"),
        anything
      )
    end

    it "renders avatar initial when no photo is attached" do
      generator = described_class.new
      wicked_instance = instance_double(WickedPdf)
      allow(WickedPdf).to receive(:new).and_return(wicked_instance)
      allow(wicked_instance).to receive(:pdf_from_string).and_return("pdf")

      generator.send(:render_pdf, biodata)

      # Avatar initial "R" should appear, no data URI
      expect(wicked_instance).to have_received(:pdf_from_string).with(
        a_string_including(">R<"),
        anything
      )
    end
  end

  describe "card template content" do
    let(:generator) { described_class.new }

    it "includes key biodata fields in the HTML" do
      biodata = create(:biodata, :published,
        full_name: "Test Person",
        education: "MBA",
        occupation: "Engineer",
        city: "Indore",
        state: "Madhya Pradesh",
        height_cm: 175
      )

      controller = ApplicationController.new
      controller.request = ActionDispatch::Request.new(
        Rack::MockRequest.env_for("https://www.samaj-darshan.com/biodatas/#{biodata.id}/whatsapp_card")
      )
      html = controller.render_to_string(
        template: "biodatas/whatsapp_card",
        layout: "whatsapp_card",
        assigns: { biodata: biodata, photo_data_uri: nil }
      )

      expect(html).to include("Test Person")
      expect(html).to include("MBA")
      expect(html).to include("Engineer")
      expect(html).to include("Indore")
      expect(html).to include("samaj-darshan.com")
    end

    it "renders correct card dimensions" do
      controller = ApplicationController.new
      controller.request = ActionDispatch::Request.new(
        Rack::MockRequest.env_for("https://www.samaj-darshan.com/biodatas/#{biodata.id}/whatsapp_card")
      )
      html = controller.render_to_string(
        template: "biodatas/whatsapp_card",
        layout: "whatsapp_card",
        assigns: { biodata: biodata, photo_data_uri: nil }
      )

      expect(html).to include("width:#{WhatsappCardGenerator::CARD_WIDTH}px")
      expect(html).to include("height:#{WhatsappCardGenerator::CARD_HEIGHT}px")
    end

    it "renders photo data URI when provided" do
      fake_data_uri = "data:image/jpeg;base64,/9j/fakedata=="

      controller = ApplicationController.new
      controller.request = ActionDispatch::Request.new(
        Rack::MockRequest.env_for("https://www.samaj-darshan.com/biodatas/#{biodata.id}/whatsapp_card")
      )
      html = controller.render_to_string(
        template: "biodatas/whatsapp_card",
        layout: "whatsapp_card",
        assigns: { biodata: biodata, photo_data_uri: fake_data_uri }
      )

      expect(html).to include(fake_data_uri)
    end

    it "renders avatar initial when no photo data URI" do
      controller = ApplicationController.new
      controller.request = ActionDispatch::Request.new(
        Rack::MockRequest.env_for("https://www.samaj-darshan.com/biodatas/#{biodata.id}/whatsapp_card")
      )
      html = controller.render_to_string(
        template: "biodatas/whatsapp_card",
        layout: "whatsapp_card",
        assigns: { biodata: biodata, photo_data_uri: nil }
      )

      expect(html).to include(biodata.avatar_initial)
      expect(html).not_to include("data:image")
    end

    it "shows caste in personal details" do
      biodata = create(:biodata, :published,
        full_name: "Caste Person",
        education: "B.Tech",
        city: "Indore",
        caste: "Agarwal",
        height_cm: nil,
        occupation: nil
      )

      controller = ApplicationController.new
      controller.request = ActionDispatch::Request.new(
        Rack::MockRequest.env_for("https://www.samaj-darshan.com/biodatas/#{biodata.id}/whatsapp_card")
      )
      html = controller.render_to_string(
        template: "biodatas/whatsapp_card",
        layout: "whatsapp_card",
        assigns: { biodata: biodata, photo_data_uri: nil }
      )

      expect(html).to include("Agarwal")
    end
  end
end
