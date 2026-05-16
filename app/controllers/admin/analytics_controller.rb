module Admin
  class AnalyticsController < BaseController
    before_action :require_super_admin

    def show
      human = Visit.human

      @stats = {
        today: { unique: human.today.unique_count, views: human.today.count },
        week:  { unique: human.this_week.unique_count, views: human.this_week.count },
        month: { unique: human.this_month.unique_count, views: human.this_month.count }
      }

      @top_pages = human.this_week
                     .group(:path)
                     .order(Arel.sql("COUNT(*) DESC"))
                     .limit(10)
                     .pluck(:path, Arel.sql("COUNT(*)"), Arel.sql("COUNT(DISTINCT visitor_token)"))
                     .map { |path, views, uniques| { path: path, views: views, uniques: uniques } }

      @top_cities = human.this_month
                      .where.not(city: [ nil, "" ])
                      .group(:city)
                      .order(Arel.sql("COUNT(DISTINCT visitor_token) DESC"))
                      .limit(10)
                      .pluck(:city, Arel.sql("COUNT(DISTINCT visitor_token)"))
                      .map { |city, count| { city: city, count: count } }

      month_visits = human.this_month
      @registered_count = month_visits.where.not(user_id: nil).unique_count
      @anonymous_count  = month_visits.where(user_id: nil).unique_count

      @bot_count_today = Visit.where(bot: true).today.count

      # Device & browser breakdown (this month)
      @device_stats = human.this_month.where.not(device_type: nil)
                        .group(:device_type).order(Arel.sql("COUNT(*) DESC"))
                        .pluck(:device_type, Arel.sql("COUNT(DISTINCT visitor_token)"))
                        .map { |type, count| { type: type, count: count } }

      @browser_stats = human.this_month.where.not(browser: nil)
                         .group(:browser).order(Arel.sql("COUNT(*) DESC"))
                         .limit(6)
                         .pluck(:browser, Arel.sql("COUNT(DISTINCT visitor_token)"))
                         .map { |name, count| { name: name, count: count } }

      @os_stats = human.this_month.where.not(os: nil)
                    .group(:os).order(Arel.sql("COUNT(*) DESC"))
                    .limit(6)
                    .pluck(:os, Arel.sql("COUNT(DISTINCT visitor_token)"))
                    .map { |name, count| { name: name, count: count } }

      # New vs returning
      @new_visitors = human.this_month.where(new_visitor: true).unique_count
      @returning_visitors = human.this_month.where(new_visitor: false).unique_count

      # Average page duration
      durations = human.this_month.where.not(duration_seconds: nil).where("duration_seconds > 0")
      @avg_duration = durations.any? ? durations.average(:duration_seconds).to_i : 0

      @daily_uniques = human
                         .where(visited_at: 30.days.ago..)
                         .group(Arel.sql("DATE(visited_at)"))
                         .order(Arel.sql("DATE(visited_at)"))
                         .pluck(Arel.sql("DATE(visited_at)"), Arel.sql("COUNT(DISTINCT visitor_token)"))
                         .map { |day, count| { day: day, count: count } }

      @ga_realtime = GoogleAnalyticsService.realtime_data
      @ga_reporting = GoogleAnalyticsService.reporting_data
    end

    private

    def require_super_admin
      redirect_to admin_root_path unless current_user.super_admin?
    end
  end
end
