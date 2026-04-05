class BillboardClicksController < ApplicationController
  def show
    billboard = Billboard.find(params[:id])
    billboard.track_click!

    url = billboard.link_url.presence
    if url && url.match?(%r{\Ahttps?://}i)
      redirect_to url, allow_other_host: true
    else
      redirect_to root_path
    end
  end
end
