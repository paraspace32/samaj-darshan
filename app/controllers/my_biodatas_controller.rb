class MyBiodatasController < ApplicationController
  before_action :require_login
  before_action :set_biodata, only: [ :show, :edit, :update, :submit_for_review, :template, :download_pdf ]

  def index
    @biodatas = current_user.biodatas.order(created_at: :desc)
  end

  def show; end

  def new
    @biodata = Biodata.new
  end

  def create
    @biodata = current_user.biodatas.build(biodata_params)
    if @biodata.save
      redirect_to my_biodata_path(@biodata), notice: t("biodata.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @biodata.update(biodata_params)
      @biodata.update_column(:status, 0) if @biodata.published? || @biodata.rejected?
      redirect_to my_biodata_path(@biodata), notice: t("biodata.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def submit_for_review
    @biodata.submit_for_review!
    redirect_to my_biodata_path(@biodata), notice: t("biodata.submitted")
  end

  def template
    @pdf_download_path = download_pdf_my_biodata_path(@biodata)
    render layout: "biodata_template"
  end

  def download_pdf
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

  private

  def set_biodata
    @biodata = current_user.biodatas.find_by(id: params[:id])
    redirect_to my_biodatas_path, alert: t("biodata.not_found") unless @biodata
  end

  def biodata_params
    params.require(:biodata).permit(
      :full_name, :full_name_hi, :gender, :date_of_birth,
      :caste, :mother_tongue,
      :city, :city_hi, :state, :country,
      :education, :occupation, :job_location, :annual_income,
      :height_cm, :complexion,
      :about_en, :about_hi,
      :father_name, :father_occupation, :mother_name, :mother_occupation, :siblings_count,
      :contact_phone, :contact_email,
      :partner_age_min, :partner_age_max, :partner_education, :partner_occupation, :partner_expectations,
      :photo
    )
  end
end
