require "net/http"
require "json"
require "uri"

# Registers attendees for Zoho Webinar sessions via the Zoho Meeting API.
#
# Requires ENV vars:
#   ZOHO_CLIENT_ID       — OAuth client ID from api-console.zoho.in
#   ZOHO_CLIENT_SECRET   — OAuth client secret
#   ZOHO_REFRESH_TOKEN   — Long-lived refresh token (generate once via OAuth flow)
#
# Usage:
#   service = ZohoWebinarService.new
#   result  = service.register(session_id: "1385865660", first_name: "Ravi", last_name: "Kumar", email: "ravi@example.com")
#   result[:success]   # => true/false
#   result[:join_link] # => "https://webinar.zoho.in/meeting/join/..." (on success)
#   result[:error]     # => error message (on failure)
class ZohoWebinarService
  ZOHO_ACCOUNTS_URL = "https://accounts.zoho.in/oauth/v2/token".freeze
  ZOHO_API_BASE     = "https://webinar.zoho.in/api/v1".freeze

  def register(session_id:, first_name:, last_name:, email:)
    token = access_token
    return { success: false, error: "Failed to obtain Zoho access token" } unless token

    uri = URI("#{ZOHO_API_BASE}/webinar/#{session_id}/registrant")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    body = {
      firstName: first_name,
      lastName: last_name,
      email: email
    }.to_json

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Zoho-oauthtoken #{token}"
    request["Content-Type"]  = "application/json"
    request.body = body

    Rails.logger.info "[ZohoWebinar] Registering #{email} for session #{session_id}"

    response = http.request(request)
    parsed = JSON.parse(response.body) rescue {}

    Rails.logger.info "[ZohoWebinar] Response #{response.code}: #{response.body.truncate(500)}"

    if response.code.to_i == 200 || response.code.to_i == 201
      {
        success: true,
        join_link: parsed.dig("joinLink") || parsed.dig("registrant", "joinLink"),
        message: parsed["message"] || "Registration successful"
      }
    else
      {
        success: false,
        error: parsed["message"] || parsed["error"] || "Registration failed (HTTP #{response.code})"
      }
    end
  rescue StandardError => e
    Rails.logger.error "[ZohoWebinar] Error: #{e.class} - #{e.message}"
    { success: false, error: "Connection error. Please try again." }
  end

  def access_token
    # Cache the token for 50 minutes (Zoho tokens last 60 min)
    Rails.cache.fetch("zoho_webinar_access_token", expires_in: 50.minutes) do
      refresh_access_token
    end
  end

  private

  def refresh_access_token
    uri = URI(ZOHO_ACCOUNTS_URL)

    params = {
      grant_type: "refresh_token",
      client_id: ENV["ZOHO_CLIENT_ID"],
      client_secret: ENV["ZOHO_CLIENT_SECRET"],
      refresh_token: ENV["ZOHO_REFRESH_TOKEN"]
    }

    response = Net::HTTP.post_form(uri, params)
    parsed = JSON.parse(response.body) rescue {}

    if parsed["access_token"]
      Rails.logger.info "[ZohoWebinar] Access token refreshed successfully"
      parsed["access_token"]
    else
      Rails.logger.error "[ZohoWebinar] Token refresh failed: #{response.body.truncate(300)}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[ZohoWebinar] Token refresh error: #{e.class} - #{e.message}"
    nil
  end
end
