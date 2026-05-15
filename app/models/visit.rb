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
end
