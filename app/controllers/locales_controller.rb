class LocalesController < ApplicationController
  def update
    locale = params[:locale].to_s.to_sym
    locale = I18n.default_locale unless locale.in?(I18n.available_locales)

    cookies[:locale] = { value: locale, expires: 1.year.from_now }

    # Build redirect URL with locale param so the page renders in the new locale,
    # and strip any old locale param from the referer to avoid conflicts
    back_url = URI.parse(request.referer || root_path) rescue URI.parse(root_path)
    query = Rack::Utils.parse_query(back_url.query)
    query["locale"] = locale.to_s
    back_url.query = Rack::Utils.build_query(query)
    redirect_to back_url.to_s, status: 303
  end
end
