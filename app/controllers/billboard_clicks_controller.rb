class BillboardClicksController < ApplicationController
  def show
    billboard = Billboard.find(params[:id])
    billboard.track_click!
    redirect_to billboard.link_url.presence || root_path, allow_other_host: true
  end
end
