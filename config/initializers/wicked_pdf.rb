WickedPdf.config = {
  # wkhtmltopdf-binary gem provides the binary automatically
  exe_path: Gem.bin_path("wkhtmltopdf-binary", "wkhtmltopdf"),
  layout: "biodata_pdf",
  margin: { top: 0, bottom: 0, left: 0, right: 0 },
  disable_smart_shrinking: false,
  print_media_type: true
}
