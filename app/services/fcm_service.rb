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
    total = PushSubscription.count
    Rails.logger.info "[Push] broadcast starting | title=#{title.inspect} total_subscribers=#{total}"

    service = new
    token   = service.access_token
    unless token
      Rails.logger.error "[Push] broadcast aborted: could not obtain FCM access token"
      return
    end

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
      when :ok
        results[:sent] += 1
        Rails.logger.debug "[Push] sent | sub_id=#{sub.id} user=#{sub.user_id || "anon"} platform=#{sub.platform}"
      when :invalid
        Rails.logger.warn "[Push] invalid token removed | sub_id=#{sub.id} user=#{sub.user_id || "anon"} platform=#{sub.platform}"
        results[:removed] += 1
        sub.destroy
      else
        results[:failed] += 1
        Rails.logger.warn "[Push] delivery failed | sub_id=#{sub.id} user=#{sub.user_id || "anon"} platform=#{sub.platform}"
      end
    end

    Rails.logger.info "[Push] broadcast done | sent=#{results[:sent]} failed=#{results[:failed]} removed=#{results[:removed]} title=#{title.inspect}"
    results
  end

  # Send to a single FCM token
  def self.send_to_token(token, title:, body:, url: nil, image: nil)
    Rails.logger.info "[Push] send_to_token | title=#{title.inspect} token=#{token&.slice(0, 12)}..."
    service = new
    access  = service.access_token
    unless access
      Rails.logger.error "[Push] send_to_token aborted: could not obtain FCM access token"
      return
    end

    result = service.push(fcm_token: token, title: title, body: body, url: url, image: image, access_token: access)
    Rails.logger.info "[Push] send_to_token result=#{result} | token=#{token&.slice(0, 12)}..."
    result
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
    token = creds.fetch_access_token!["access_token"]
    Rails.logger.debug "[Push] FCM access token obtained (length=#{token&.length})"
    token
  rescue => e
    Rails.logger.error "[Push] FCM access_token error: #{e.class} #{e.message}"
    nil
  end

  # ── Send one message ──────────────────────────────────────────────────────────

  def push(fcm_token:, title:, body:, url: nil, image: nil, access_token:)
    project_id = firebase_project_id
    return :error if project_id.blank?

    uri     = URI("https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send")
    payload = build_payload(fcm_token, title, body, url, image)

    http              = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = true
    http.open_timeout = 5   # seconds to open connection
    http.read_timeout = 10  # seconds to wait for response
    request           = Net::HTTP::Post.new(uri)
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
    # Use data-only webpush payload so the browser does NOT auto-display a
    # notification from the push message itself.  The service worker's
    # onBackgroundMessage handler reads these data fields and calls
    # showNotification exactly once.  Using webpush.notification here would
    # trigger a second display (browser auto-show + SW handler = 2 toasts).
    msg = {
      token:   token,
      webpush: {
        data: {
          title: title.to_s,
          body:  body.to_s,
          url:   url.presence || "/",
          image: image.to_s
        }
      }
    }

    { message: msg }
  end

  def parse_response(response, token)
    case response.code.to_i
    when 200      then :ok
    when 404, 410 then :invalid   # token unregistered / not found
    else
      Rails.logger.warn "[Push] FCM HTTP #{response.code} for token #{token[0..10]}...: #{response.body&.slice(0, 200)}"
      :error
    end
  end

  def firebase_credentials
    # Option 1: single JSON string in ENV (set via GitHub secret)
    return ENV["FIREBASE_SERVICE_ACCOUNT_JSON"] if ENV["FIREBASE_SERVICE_ACCOUNT_JSON"].present?

    # Option 2: single JSON string in Rails credentials
    json_str = Rails.application.credentials.dig(:firebase, :service_account_json)
    return json_str if json_str.present?

    # Option 3: structured hash in Rails credentials (stored as YAML fields)
    sa = Rails.application.credentials.dig(:firebase, :service_account)
    return nil unless sa

    sa_hash = sa.is_a?(Hash) ? sa : sa.to_h
    # Ensure private_key has real newlines (credentials may store as literal block)
    sa_hash = sa_hash.stringify_keys
    sa_hash["private_key"] = sa_hash["private_key"].to_s.gsub("\\n", "\n")
    sa_hash.to_json
  end

  def firebase_project_id
    Rails.application.credentials.dig(:firebase, :project_id) ||
      ENV["FIREBASE_PROJECT_ID"]
  end
end
