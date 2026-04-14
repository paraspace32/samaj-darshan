class MyBiodatasController < ApplicationController
  before_action :require_login
  before_action :set_biodata, only: [ :show, :edit, :update, :submit_for_review ]

  def show; end

  def new
    if current_user.biodata.present?
      redirect_to my_biodata_path, notice: t("biodata.already_exists") and return
    end
    @biodata = Biodata.new
  end

  def create
    if current_user.biodata.present?
      redirect_to my_biodata_path and return
    end
    @biodata = current_user.build_biodata(biodata_params)
    if @biodata.save
      redirect_to my_biodata_path, notice: t("biodata.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @biodata.update(biodata_params)
      @biodata.update_column(:status, 0) if @biodata.published? || @biodata.rejected?
      redirect_to my_biodata_path, notice: t("biodata.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def submit_for_review
    @biodata.submit_for_review!
    redirect_to my_biodata_path, notice: t("biodata.submitted")
  end

  private

  def set_biodata
    @biodata = current_user.biodata
    redirect_to new_my_biodata_path unless @biodata
  end

  def biodata_params
    params.require(:biodata).permit(
      :full_name, :full_name_hi, :gender, :date_of_birth,
      :religion, :caste, :mother_tongue,
      :city, :state, :country,
      :education, :occupation, :annual_income,
      :height_cm, :complexion,
      :about_en, :about_hi,
      :father_occupation, :mother_occupation, :siblings_count,
      :contact_phone, :contact_email,
      :photo
    )
  end
end
