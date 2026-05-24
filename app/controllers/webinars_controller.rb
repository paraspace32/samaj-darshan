class WebinarsController < ApplicationController
  def index
    webinar = Webinar.upcoming.first || Webinar.past.order(starts_at: :desc).first
    if webinar
      redirect_to webinar_path(webinar), status: :moved_permanently
    else
      redirect_to root_path
    end
  end

  def show
    @webinar = Webinar.published.find(params[:id])
  end
end
