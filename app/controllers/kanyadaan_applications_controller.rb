class KanyadaanApplicationsController < ApplicationController
  def new
    @application = KanyadaanApplication.new
  end

  def create
    @application = KanyadaanApplication.new(application_params)

    if @application.save
      redirect_to kanyadaan_success_path, notice: t("kanyadaan.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
  end

  private

  def application_params
    params.require(:kanyadaan_application).permit(:girl_name, :parent_name, :contact, :location, :notes)
  end
end
