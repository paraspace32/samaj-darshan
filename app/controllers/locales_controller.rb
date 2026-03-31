class LocalesController < ApplicationController
  def update
    locale = params[:locale].to_s.to_sym
    locale = I18n.default_locale unless locale.in?(I18n.available_locales)

    cookies[:locale] = { value: locale, expires: 1.year.from_now }
    redirect_back fallback_location: root_path
  end
end
