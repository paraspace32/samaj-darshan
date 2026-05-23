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

    unless @webinar.upcoming?
      redirect_to webinar_path(@webinar), alert: t("webinar.registration_closed")
      return
    end

    registration = @webinar.webinar_registrations.build(
      name: params[:name].to_s.strip,
      phone: params[:phone].to_s.strip
    )

    if registration.save
      redirect_to webinar_path(@webinar), notice: t("webinar.registration_success")
    else
      redirect_to webinar_path(@webinar), alert: registration.errors.full_messages.join(", ")
    end
  end
end
