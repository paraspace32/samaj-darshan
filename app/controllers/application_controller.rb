class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include Trackable

  allow_browser versions: { safari: 14, chrome: 80, firefox: 80, opera: 70, ie: false }
  stale_when_importmap_changes

  before_action :set_locale
  before_action :load_consent_pending_biodata

  private

  def set_locale
    locale = params[:locale] || cookies[:locale] || I18n.default_locale
    I18n.locale = locale.to_sym.in?(I18n.available_locales) ? locale.to_sym : I18n.default_locale
  end

  def load_consent_pending_biodata
    return unless logged_in?
    return if current_user.admin_panel_access?
    @consent_pending_biodata = current_user.biodatas.pending_consent.where.not(created_by_id: nil).first
  end

  def switch_locale_path
    new_locale = I18n.locale == :hi ? :en : :hi
    set_locale_path(locale: new_locale)
  end
  helper_method :switch_locale_path

  def visitor_city
    @visitor_city ||= GeolocationService.lookup(request.remote_ip)[:city]
  end
  helper_method :visitor_city

  def visitor_region
    @visitor_region ||= if cookies[:region].present?
      Region.active.find_by(slug: cookies[:region])
    elsif (cached_slug = Rails.cache.read("ip_region/#{request.remote_ip}"))
      Region.active.find_by(slug: cached_slug)
    elsif visitor_city.present?
      Region.active.ordered.where("name_en ILIKE ?", "%#{visitor_city}%").first
    end
  end
  helper_method :visitor_region

  def visitor_location_name
    if visitor_region
      visitor_region.send(I18n.locale == :hi ? :name_hi : :name_en).presence || visitor_region.name_en
    else
      visitor_city
    end
  end
  helper_method :visitor_location_name
end
