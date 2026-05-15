class RecordVisitJob < ApplicationJob
  queue_as :default

  def perform(ip:, user_agent:, path:, referrer:, user_id:, visited_at:)
    is_bot = Visit.bot_user_agent?(user_agent)
    token  = Visit.generate_token(ip, user_agent)
    geo    = is_bot ? { city: nil, country: nil } : GeolocationService.lookup(ip)

    Visit.create!(
      visitor_token: token,
      ip_address:    ip,
      user_agent:    user_agent&.truncate(512),
      path:          path,
      referrer:      referrer&.truncate(512),
      city:          geo[:city],
      country:       geo[:country],
      user_id:       user_id,
      bot:           is_bot,
      visited_at:    visited_at
    )
  end
end
