class WebinarsController < ApplicationController
  def index
    @webinar = Webinar.upcoming.includes(:host).with_attached_cover_image.first
    @past_recordings = Webinar.past.order(starts_at: :desc)
                              .includes(:host).with_attached_cover_image
                              .limit(20)
  end

  def show
    @webinar = Webinar.published.find_by(id: params[:id])
    redirect_to(webinars_path) and return unless @webinar

    @past_recordings = Webinar.past.order(starts_at: :desc)
                              .includes(:host).with_attached_cover_image
                              .where.not(id: @webinar.id)
                              .limit(20)
  end
end
