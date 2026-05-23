class WebinarsController < ApplicationController
  def index
    @upcoming = Webinar.upcoming.includes(:host).with_attached_cover_image.limit(20)
    @past = Webinar.past.order(starts_at: :desc).includes(:host).with_attached_cover_image.limit(20)
  end

  def show
    @webinar = Webinar.published.find(params[:id])
    Rails.logger.info "[WEBINAR SHOW] id=#{@webinar.id} title=#{@webinar.title_en} status=#{@webinar.status}"
    Rails.logger.info "[WEBINAR SHOW] meeting_url=#{@webinar.meeting_url.inspect} upcoming?=#{@webinar.upcoming?} live_now?=#{@webinar.live_now?}"
    Rails.logger.info "[WEBINAR SHOW] params[:registered]=#{params[:registered].inspect} meeting_url_present?=#{@webinar.meeting_url.present?}"
    Rails.logger.info "[WEBINAR SHOW] will_show_join_button=#{params[:registered].present? && @webinar.meeting_url.present?}"
  end

  def register
    @webinar = Webinar.published.find(params[:id])
    Rails.logger.info "[WEBINAR REGISTER] id=#{@webinar.id} name=#{params[:name]} phone=#{params[:phone]}"

    unless @webinar.upcoming?
      Rails.logger.info "[WEBINAR REGISTER] REJECTED — not upcoming"
      redirect_to webinar_path(@webinar), alert: t("webinar.registration_closed")
      return
    end

    registration = @webinar.webinar_registrations.build(
      name: params[:name].to_s.strip,
      phone: params[:phone].to_s.strip
    )

    if registration.save
      Rails.logger.info "[WEBINAR REGISTER] SUCCESS — redirecting with registered=1"
      Rails.logger.info "[WEBINAR REGISTER] redirect_url=#{webinar_path(@webinar, registered: 1)}"
      redirect_to webinar_path(@webinar, registered: 1), notice: t("webinar.registration_success")
    else
      Rails.logger.info "[WEBINAR REGISTER] FAILED — #{registration.errors.full_messages.join(', ')}"
      redirect_to webinar_path(@webinar), alert: registration.errors.full_messages.join(", ")
    end
  end
end
