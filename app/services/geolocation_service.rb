class GeolocationService
  PRIVATE_IP = /\A(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|::1|0\.0\.0\.0)/

  def self.lookup(ip)
    return { city: nil, country: nil } if ip.blank? || ip.match?(PRIVATE_IP)

    Rails.cache.fetch("ip_geo/#{ip}", expires_in: 24.hours) do
      require "net/http"
      uri = URI("http://ip-api.com/json/#{CGI.escape(ip)}?fields=city,country,status&lang=en")
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        if data["status"] == "success"
          { city: data["city"].to_s.strip.presence, country: data["country"].to_s.strip.presence }
        else
          { city: nil, country: nil }
        end
      else
        { city: nil, country: nil }
      end
    rescue StandardError => e
      Rails.logger.warn "[GeolocationService] Lookup failed for #{ip}: #{e.message}"
      { city: nil, country: nil }
    end
  end
end
