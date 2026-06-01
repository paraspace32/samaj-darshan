class FlagBotVisitorsJob < ApplicationJob
  queue_as :default

  DAILY_VIEW_THRESHOLD = 20
  ZERO_DURATION_VIEW_THRESHOLD = 5

  def perform(date = Date.yesterday)
    date = Date.parse(date) if date.is_a?(String)
    range = date.beginning_of_day..date.end_of_day

    flagged = 0

    # Never flag logged-in users as bots — they are real authenticated users
    logged_in_tokens = Visit.where(visited_at: range).where.not(user_id: nil)
                            .distinct.pluck(:visitor_token)

    high_frequency_tokens(range).each do |token|
      next if logged_in_tokens.include?(token)
      flagged += Visit.where(visitor_token: token, bot: false).update_all(bot: true)
    end

    zero_duration_tokens(range).each do |token|
      next if logged_in_tokens.include?(token)
      flagged += Visit.where(visitor_token: token, bot: false).update_all(bot: true)
    end

    multi_token_ips(range).each do |ip|
      flagged += Visit.where(ip_address: ip, bot: false).where(user_id: nil).update_all(bot: true)
    end

    Rails.logger.info "FlagBotVisitors | date=#{date} | flagged=#{flagged} visits"
    flagged
  end

  private

  def high_frequency_tokens(range)
    Visit.human.where(visited_at: range)
         .group(:visitor_token)
         .having("COUNT(*) > ?", DAILY_VIEW_THRESHOLD)
         .pluck(:visitor_token)
  end

  def zero_duration_tokens(range)
    Visit.human.where(visited_at: range)
         .group(:visitor_token)
         .having("COUNT(*) - COUNT(duration_seconds) > ?", ZERO_DURATION_VIEW_THRESHOLD)
         .pluck(:visitor_token)
  end

  def multi_token_ips(range)
    Visit.human.where(visited_at: range)
         .group(:ip_address)
         .having("COUNT(DISTINCT visitor_token) > 3")
         .pluck(:ip_address)
  end
end
