class BiodatasController < ApplicationController
  before_action :require_login

  def index
    @biodatas = Biodata.visible
                       .with_attached_photo
                       .for_gender(params[:gender])
                       .for_age_range(params[:age_min], params[:age_max])
                       .for_city(params[:city])
                       .for_education(params[:education])
    @per_page = 24
    @page = [ params[:page].to_i, 1 ].max
    @total_count = @biodatas.count
    @biodatas = @biodatas.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    @biodata = Biodata.published.find(params[:id])
  end

  def template
    @biodata = Biodata.published.find(params[:id])
    @pdf_download_path = download_pdf_biodata_path(@biodata)
    render layout: "biodata_template"
  end

  def download_pdf
    @biodata = Biodata.published.find(params[:id])
    filename = "biodata_#{@biodata.full_name.parameterize}_#{@biodata.id}.pdf"
    render pdf: filename,
           template: "biodatas/template",
           layout: "biodata_pdf",
           page_size: "A4",
           margin: { top: 0, bottom: 0, left: 0, right: 0 },
           disable_smart_shrinking: true,
           print_media_type: true,
           disposition: "attachment"
  end
end
