class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

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
end
