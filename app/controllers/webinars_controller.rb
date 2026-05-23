class WebinarsController < ApplicationController
  def index
    @upcoming = Webinar.upcoming.includes(:host).with_attached_cover_image.limit(20)
    @past = Webinar.past.order(starts_at: :desc).includes(:host).with_attached_cover_image.limit(20)
  end

  def show
    @webinar = Webinar.published.find(params[:id])
  end

  def register
    @webinar = Webinar.published.find(params[:id])

    unless @webinar.upcoming? && @webinar.zoho_session_id.present?
      redirect_to webinar_path(@webinar), alert: t("webinar.registration_closed")
      return
    end

    first_name = params[:first_name].to_s.strip
    last_name  = params[:last_name].to_s.strip
    email      = params[:email].to_s.strip

    if first_name.blank? || last_name.blank? || email.blank?
      redirect_to webinar_path(@webinar), alert: t("webinar.fill_all_fields")
      return
    end

    service = ZohoWebinarService.new
    result = service.register(
      session_id: @webinar.zoho_session_id,
      first_name: first_name,
      last_name: last_name,
      email: email
    )

    if result[:success]
      redirect_to webinar_path(@webinar), notice: t("webinar.registration_success")
    else
      redirect_to webinar_path(@webinar), alert: result[:error]
    end
  end
end
