class AnalyticsDailyReportJob < ApplicationJob
  queue_as :default

  REPORT_LOG = Logger.new(Rails.root.join("log", "analytics_daily_report.log"), "daily").tap do |l|
    l.formatter = proc { |sev, time, _, msg| "#{time.strftime('%Y-%m-%d %H:%M:%S')} [#{sev}] #{msg}\n" }
  end

  def perform(date = Date.yesterday)
    date = Date.parse(date) if date.is_a?(String)
    range = date.beginning_of_day..date.end_of_day
    human = Visit.human.where(visited_at: range)

    visit_unique  = human.unique_count
    visit_views   = human.count
    visit_new     = human.where(new_visitor: true).unique_count
    visit_return  = human.where(new_visitor: false).unique_count
    visit_bots    = Visit.where(bot: true, visited_at: range).count

    top_pages = human.group(:path).order(Arel.sql("COUNT(*) DESC")).limit(5)
                  .pluck(:path, Arel.sql("COUNT(*)"), Arel.sql("COUNT(DISTINCT visitor_token)"))
                  .map { |p, v, u| { path: p, views: v, uniques: u } }

    top_cities = human.where.not(city: [ nil, "" ])
                   .group(:city).order(Arel.sql("COUNT(DISTINCT visitor_token) DESC")).limit(5)
                   .pluck(:city, Arel.sql("COUNT(DISTINCT visitor_token)"))
                   .map { |c, n| { city: c, count: n } }

    device_data = human.where.not(device_type: nil)
                    .group(:device_type).order(Arel.sql("COUNT(*) DESC"))
                    .pluck(:device_type, Arel.sql("COUNT(*)"))
                    .map { |t, c| { type: t, count: c } }

    durations = human.where.not(duration_seconds: nil).where("duration_seconds > 0")
    avg_duration = durations.any? ? durations.average(:duration_seconds).to_i : 0

    ga = GoogleAnalyticsService.daily_users(start_date: date)

    user_delta_pct = nil
    view_delta_pct = nil

    if ga
      user_delta_pct = ga[:users] > 0 ? (((visit_unique - ga[:users]).to_f / ga[:users]) * 100).round(1) : 0
      view_delta_pct = ga[:pageviews] > 0 ? (((visit_views - ga[:pageviews]).to_f / ga[:pageviews]) * 100).round(1) : 0
    end

    report = AnalyticsDailyReport.find_or_initialize_by(date: date)
    report.update!(
      visit_unique: visit_unique,
      visit_views: visit_views,
      visit_new: visit_new,
      visit_returning: visit_return,
      visit_bots: visit_bots,
      visit_avg_duration: avg_duration,
      ga_users: ga&.dig(:users),
      ga_sessions: ga&.dig(:sessions),
      ga_pageviews: ga&.dig(:pageviews),
      ga_new_users: ga&.dig(:new_users),
      top_pages: top_pages,
      top_cities: top_cities,
      devices: device_data,
      user_delta_pct: user_delta_pct,
      view_delta_pct: view_delta_pct
    )

    log_report(date, report, ga)
    report
  end

  private

  def log_report(date, report, ga)
    REPORT_LOG.info "DAILY REPORT | date=#{date} | visit_unique=#{report.visit_unique} visit_views=#{report.visit_views} | ga_users=#{ga&.dig(:users) || 'nil'} ga_pageviews=#{ga&.dig(:pageviews) || 'nil'} | user_delta=#{report.user_delta_pct || 'n/a'} view_delta=#{report.view_delta_pct || 'n/a'}"
  rescue => e
    REPORT_LOG.error "LOG_ERROR | #{e.class}: #{e.message}"
  end
end
