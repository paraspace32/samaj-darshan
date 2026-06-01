class WhatsappCardGenerator
  CARD_WIDTH  = 540
  CARD_HEIGHT = 720
  DPI         = 300
  # Bump this version to force regeneration when template changes
  TEMPLATE_VERSION = 4

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

  # Renders the SAME biodatas/template.html.erb used by the app,
  # wrapped in a tight card layout. Photo is embedded as base64
  # because wkhtmltopdf can't access Rails routes/GCS URLs.
  def render_pdf(biodata)
    photo_data_uri = build_photo_data_uri(biodata)

    # Use ApplicationController so helpers (optimized_image_tag, t, etc.) work
    controller = ApplicationController.new
    controller.request = ActionDispatch::Request.new(
      Rack::MockRequest.env_for("https://www.samaj-darshan.com/biodatas/#{biodata.id}/whatsapp_card")
    )
    html = controller.render_to_string(
      template: "biodatas/template",
      layout: "whatsapp_card",
      assigns: { biodata: biodata }
    )

    # Replace URL-based photo <img> with base64 data URI (wkhtmltopdf can't access GCS URLs)
    if photo_data_uri.present?
      html.gsub!(/<img[^>]*?style="width:100%;height:100%;object-fit:cover[^"]*"[^>]*\/?>/) do
        %(<img src="#{photo_data_uri}" style="width:100%;height:100%;object-fit:cover;display:block;" />)
      end
    end

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
    # Use vips to convert PDF first page to JPEG at high DPI
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

    image.jpegsave_buffer(Q: 92)
  end
end
