class RecordVisitJob < ApplicationJob
  queue_as :default

  def perform(ip:, user_agent:, path:, referrer:, user_id:, visited_at:)
    is_bot = Visit.bot_user_agent?(user_agent)
    token  = Visit.generate_token(ip, user_agent)
    city, country = resolve_location(ip) unless is_bot

    Visit.create!(
      visitor_token: token,
      ip_address:    ip,
      user_agent:    user_agent&.truncate(512),
      path:          path,
      referrer:      referrer&.truncate(512),
      city:          city,
      country:       country,
      user_id:       user_id,
      bot:           is_bot,
      visited_at:    visited_at
    )
  end

  private

  def resolve_location(ip)
    return [ nil, nil ] if ip.blank? || ip == "127.0.0.1" || ip.start_with?("192.168.", "10.", "172.")

    cache_key = "ip_geo/#{Digest::MD5.hexdigest(ip)}"
    result = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      uri = URI("http://ip-api.com/json/#{ip}?fields=city,country")
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        { city: data["city"], country: data["country"] }
      end
    rescue StandardError => e
      Rails.logger.warn "[RecordVisitJob] Geo lookup failed for #{ip}: #{e.message}"
      nil
    end

    [ result&.dig(:city), result&.dig(:country) ]
  end
end
