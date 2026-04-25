require "net/http"
require "json"

# Sends push notifications via Firebase Cloud Messaging HTTP v1 API.
# Uses a Google service account (JSON stored in credentials/ENV) for OAuth2.
#
# Usage:
#   FcmService.broadcast(title: "Breaking News", body: "...", url: "https://...")
#   FcmService.send_to_token(token, title: "...", body: "...", url: "...")
class FcmService
  FCM_SCOPE   = "https://www.googleapis.com/auth/firebase.messaging".freeze
  GOOGLE_AUTH = "https://oauth2.googleapis.com/token".freeze

  # Send to every stored subscription (runs inside a job — do NOT call from request cycle)
  def self.broadcast(title:, body:, url: nil, image: nil)
    service = new
    token   = service.access_token
    return unless token

    results = { sent: 0, failed: 0, removed: 0 }

    PushSubscription.find_each do |sub|
      status = service.push(
        fcm_token: sub.token,
        title:     title,
        body:      body,
        url:       url,
        image:     image,
        access_token: token
      )

      case status
      when :ok      then results[:sent]    += 1
      when :invalid then results[:removed] += 1; sub.destroy
      else               results[:failed]  += 1
      end
    end

    Rails.logger.info "[FCM] broadcast done: #{results.inspect}"
    results
  end

  # Send to a single FCM token
  def self.send_to_token(token, title:, body:, url: nil, image: nil)
    service = new
    access  = service.access_token
    return unless access

    service.push(fcm_token: token, title: title, body: body, url: url, image: image, access_token: access)
  end

  # ── OAuth2 ────────────────────────────────────────────────────────────────────

  def access_token
    @access_token ||= fetch_access_token
  end

  def fetch_access_token
    creds_json = firebase_credentials
    return nil if creds_json.blank?

    require "googleauth"
    creds = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(creds_json),
      scope: FCM_SCOPE
    )
    creds.fetch_access_token!["access_token"]
  rescue => e
    Rails.logger.error "[FCM] access_token error: #{e.message}"
    nil
  end

  # ── Send one message ──────────────────────────────────────────────────────────

  def push(fcm_token:, title:, body:, url: nil, image: nil, access_token:)
    project_id = firebase_project_id
    return :error if project_id.blank?

    uri     = URI("https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send")
    payload = build_payload(fcm_token, title, body, url, image)

    http          = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl  = true
    request       = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"]  = "application/json"
    request.body = payload.to_json

    response = http.request(request)
    parse_response(response, fcm_token)
  rescue => e
    Rails.logger.error "[FCM] push error for token #{fcm_token[0..10]}...: #{e.message}"
    :error
  end

  private

  def build_payload(token, title, body, url, image)
    notification = { title: title, body: body }
    notification[:image] = image if image.present?

    webpush_notification = notification.merge(
      icon:  "/icon-192.png",
      badge: "/icon-192.png",
      vibrate: [200, 100, 200]
    )
    webpush_notification[:image] = image if image.present?

    msg = {
      token:        token,
      notification: notification,
      webpush: {
        notification: webpush_notification,
        fcm_options:  { link: url.presence || "/" }
      },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } }
      }
    }

    { message: msg }
  end

  def parse_response(response, token)
    case response.code.to_i
    when 200      then :ok
    when 404, 410 then :invalid   # token unregistered / not found
    else
      Rails.logger.warn "[FCM] HTTP #{response.code} for token #{token[0..10]}...: #{response.body}"
      :error
    end
  end

  def firebase_credentials
    # Stored as a single JSON string in Rails credentials or ENV
    Rails.application.credentials.dig(:firebase, :service_account_json) ||
      ENV["FIREBASE_SERVICE_ACCOUNT_JSON"]
  end

  def firebase_project_id
    Rails.application.credentials.dig(:firebase, :project_id) ||
      ENV["FIREBASE_PROJECT_ID"]
  end
end
