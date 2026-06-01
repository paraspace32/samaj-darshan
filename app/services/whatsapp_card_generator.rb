class WhatsappCardGenerator
  CARD_WIDTH  = 540
  CARD_HEIGHT = 720
  DPI         = 300
  # Bump this version to force regeneration when template changes
  TEMPLATE_VERSION = 6

  # Generate (or return cached) WhatsApp card image for a biodata.
  # Returns the ActiveStorage attachment.
  def generate(biodata)
    if biodata.whatsapp_card.attached?
      expected_filename = "biodata_card_#{biodata.id}_v#{TEMPLATE_VERSION}.jpg"
      return biodata.whatsapp_card if biodata.whatsapp_card.blob.filename.to_s == expected_filename

      biodata.whatsapp_card.purge
    end

    pdf_binary = render_pdf(biodata)
    jpeg_binary = pdf_to_jpeg(pdf_binary)

    biodata.whatsapp_card.attach(
      io: StringIO.new(jpeg_binary),
      filename: "biodata_card_#{biodata.id}_v#{TEMPLATE_VERSION}.jpg",
      content_type: "image/jpeg"
    )

    biodata.whatsapp_card
  end

  private

  def render_pdf(biodata)
    photo_data_uri = build_photo_data_uri(biodata)

    # Use ApplicationController for helper access (t, etc.)
    controller = ApplicationController.new
    controller.request = ActionDispatch::Request.new(
      Rack::MockRequest.env_for("https://www.samaj-darshan.com/biodatas/#{biodata.id}/whatsapp_card")
    )
    html = controller.render_to_string(
      template: "biodatas/whatsapp_card",
      layout: "whatsapp_card",
      assigns: { biodata: biodata, photo_data_uri: photo_data_uri }
    )

    WickedPdf.new.pdf_from_string(
      html,
      page_width:  "#{CARD_WIDTH / 96.0 * 25.4}mm",
      page_height: "#{CARD_HEIGHT / 96.0 * 25.4}mm",
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
      disable_smart_shrinking: true,
      print_media_type: false,
      zoom: 1,
      dpi: 150
    )
  end

  def build_photo_data_uri(biodata)
    return nil unless biodata.photo.attached?

    blob = biodata.photo.blob
    photo_bytes = blob.download
    mime = blob.content_type || "image/jpeg"
    "data:#{mime};base64,#{Base64.strict_encode64(photo_bytes)}"
  rescue => e
    Rails.logger.warn "WhatsappCardGenerator: Could not load photo for biodata #{biodata.id}: #{e.message}"
    nil
  end

  def pdf_to_jpeg(pdf_binary)
    image = Vips::Image.new_from_buffer(pdf_binary, "", dpi: DPI, n: 1)

    scale_x = CARD_WIDTH.to_f / image.width
    scale_y = CARD_HEIGHT.to_f / image.height
    scale = [ scale_x, scale_y ].max
    image = image.resize(scale)

    if image.width > CARD_WIDTH || image.height > CARD_HEIGHT
      left = [ (image.width - CARD_WIDTH) / 2, 0 ].max
      top = [ (image.height - CARD_HEIGHT) / 2, 0 ].max
      image = image.crop(left, top, CARD_WIDTH, CARD_HEIGHT)
    end

    image = image.flatten(background: [ 255, 255, 255 ]) if image.has_alpha?

    image.jpegsave_buffer(Q: 92)
  end
end
