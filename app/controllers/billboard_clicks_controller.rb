class BillboardClicksController < ApplicationController
  def show
    billboard = Billboard.find(params[:id])
    billboard.track_click!
    redirect_to safe_billboard_url(billboard.link_url), allow_other_host: true
  end

  private

  def safe_billboard_url(url)
    return root_url unless url.present?

    uri = URI.parse(url)
    uri.scheme&.match?(/\Ahttps?\z/i) ? url : root_url
  rescue URI::InvalidURIError
    root_url
  end
end
