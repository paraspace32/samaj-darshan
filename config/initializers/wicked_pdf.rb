WickedPdf.configure do |config|
  # wkhtmltopdf-binary gem provides the binary automatically
  config.exe_path = Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf")
  config.layout = "biodata_pdf"
  config.margin = { top: 0, bottom: 0, left: 0, right: 0 }
  config.disable_smart_shrinking = false
  config.print_media_type = true
end
