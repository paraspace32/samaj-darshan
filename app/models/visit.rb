class Visit < ApplicationRecord
  belongs_to :user, optional: true

  scope :human,      -> { where(bot: false) }
  scope :today,      -> { where(visited_at: Time.current.beginning_of_day..) }
  scope :this_week,  -> { where(visited_at: Time.current.beginning_of_week..) }
  scope :this_month, -> { where(visited_at: Time.current.beginning_of_month..) }
  scope :unique_count, -> { select(:visitor_token).distinct.count }

  BOT_PATTERNS = /bot|crawl|spider|slurp|bingpreview|facebookexternalhit|whatsapp\/2|
    mediapartners|google-read-aloud|headlesschrome|phantomjs|selenium|
    curl|wget|python-requests|go-http-client|java\/|httpie|postman|
    ahrefsbot|semrushbot|dotbot|mj12bot|yandexbot|baiduspider|
    sogou|exabot|ia_archiver|archive\.org_bot|gptbot|claudebot/ix.freeze

  def self.bot_user_agent?(ua)
    return true if ua.blank?
    BOT_PATTERNS.match?(ua)
  end

  def self.generate_token(ip, user_agent)
    Digest::SHA256.hexdigest("#{ip}||#{user_agent}")
  end

  def self.parse_device(ua)
    return { device_type: "unknown", browser: "unknown", os: "unknown" } if ua.blank?

    os = case ua
         when /android/i then "Android"
         when /iphone|ipad|ipod/i then "iOS"
         when /windows/i then "Windows"
         when /macintosh|mac os/i then "macOS"
         when /linux/i then "Linux"
         else "Other"
         end

    browser = case ua
              when /edg\//i then "Edge"
              when /opr|opera/i then "Opera"
              when /samsungbrowser/i then "Samsung"
              when /chrome|crios/i then "Chrome"
              when /firefox|fxios/i then "Firefox"
              when /safari/i then "Safari"
              else "Other"
              end

    device_type = case ua
                  when /mobile|android.*phone|iphone/i then "mobile"
                  when /tablet|ipad|android(?!.*mobile)/i then "tablet"
                  else "desktop"
                  end

    { device_type: device_type, browser: browser, os: os }
  end
end
