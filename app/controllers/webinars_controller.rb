class WebinarsController < ApplicationController
  def index
    @upcoming = Webinar.upcoming.includes(:host).with_attached_cover_image.limit(20)
    @past = Webinar.past.order(starts_at: :desc).includes(:host).with_attached_cover_image.limit(20)
  end

  def show
    @webinar = Webinar.published.find(params[:id])
  end
end
