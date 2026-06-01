class WhatsappCardGenerator
  CARD_WIDTH  = 540
  CARD_HEIGHT = 720
  DPI         = 200
  # Bump this version to force regeneration when template changes
  TEMPLATE_VERSION = 2

  # Generate (or return cached) WhatsApp card image for a biodata.
  # Returns the ActiveStorage attachment.
  def generate(biodata)
    if biodata.whatsapp_card.attached?
      # Regenerate if template version changed (filename encodes version)
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
    # Build photo data URI for wkhtmltopdf (it renders from temp file, can't access Rails routes)
    photo_data_uri = nil
    if biodata.photo.attached?
      begin
        blob = biodata.photo.blob
        photo_bytes = blob.download
        mime = blob.content_type || "image/jpeg"
        photo_data_uri = "data:#{mime};base64,#{Base64.strict_encode64(photo_bytes)}"
      rescue => e
        Rails.logger.warn "WhatsappCardGenerator: Could not load photo for biodata #{biodata.id}: #{e.message}"
      end
    end

    controller = ActionController::Base.new
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
      dpi: 96
    )
  end

  def pdf_to_jpeg(pdf_binary)
    # Use vips to convert PDF first page to JPEG
    image = Vips::Image.new_from_buffer(pdf_binary, "", dpi: DPI, n: 1)

    # Scale to exact card dimensions
    scale_x = CARD_WIDTH.to_f / image.width
    scale_y = CARD_HEIGHT.to_f / image.height
    scale = [ scale_x, scale_y ].max
    image = image.resize(scale)

    # Crop to exact dimensions if needed
    if image.width > CARD_WIDTH || image.height > CARD_HEIGHT
      left = [ (image.width - CARD_WIDTH) / 2, 0 ].max
      top = [ (image.height - CARD_HEIGHT) / 2, 0 ].max
      image = image.crop(left, top, CARD_WIDTH, CARD_HEIGHT)
    end

    # Flatten alpha channel to white background if present
    image = image.flatten(background: [ 255, 255, 255 ]) if image.has_alpha?

    image.jpegsave_buffer(Q: 90)
  end
end
