class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_locale

  private

  def set_locale
    locale = params[:locale] || cookies[:locale] || I18n.default_locale
    I18n.locale = locale.to_sym.in?(I18n.available_locales) ? locale.to_sym : I18n.default_locale
  end

  def switch_locale_path
    new_locale = I18n.locale == :hi ? :en : :hi
    set_locale_path(locale: new_locale)
  end
  helper_method :switch_locale_path
end
