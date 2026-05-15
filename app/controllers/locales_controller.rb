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

  def set_region
    ip = request.remote_ip

    if params[:slug] == "auto"
      cookies.delete(:region)
    else
      region = Region.active.find_by(slug: params[:slug])
      if region
        cookies[:region] = { value: region.slug, expires: 1.year.from_now }
        record_region_vote(ip, region.slug)
      end
    end
    redirect_to(request.referer || root_path, status: 303)
  end

  private

  def record_region_vote(ip, slug)
    votes_key = "ip_region_votes/#{ip}"
    votes = Rails.cache.read(votes_key) || {}
    votes[slug] = (votes[slug] || 0) + 1
    Rails.cache.write(votes_key, votes, expires_in: 90.days)

    top_slug, top_count = votes.max_by { |_, count| count }
    if top_count >= 2
      Rails.cache.write("ip_region/#{ip}", top_slug, expires_in: 90.days)
    end
  end
end
