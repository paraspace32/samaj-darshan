class RecordVisitJob < ApplicationJob
  queue_as :default

  def perform(ip:, user_agent:, path:, referrer:, user_id:, visited_at:, visitor_cookie: nil)
    is_bot = Visit.bot_user_agent?(user_agent)
    token  = if visitor_cookie.present? && !is_bot
               Digest::SHA256.hexdigest(visitor_cookie)
             else
               Visit.generate_token(ip, user_agent)
             end
    geo    = is_bot ? { city: nil, country: nil } : GeolocationService.lookup(ip)
    device = Visit.parse_device(user_agent)
    new_visitor = !Visit.where(visitor_token: token).exists?

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
      visited_at:    visited_at,
      device_type:   device[:device_type],
      browser:       device[:browser],
      os:            device[:os],
      new_visitor:   new_visitor
    )
  end
end
