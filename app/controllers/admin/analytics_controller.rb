module Admin
  class AnalyticsController < BaseController
    ANALYTICS_LOG = Logger.new(Rails.root.join("log", "analytics_dashboard.log"), "daily").tap do |l|
      l.formatter = proc { |sev, time, _, msg| "#{time.strftime('%Y-%m-%d %H:%M:%S')} [#{sev}] #{msg}\n" }
    end

    before_action :require_super_admin

    def show
      human = Visit.human

      # ── Summary cards (always unfiltered) ─────────────────────────────────
      @stats = {
        today: { unique: human.today.unique_count, views: human.today.count },
        week:  { unique: human.this_week.unique_count, views: human.this_week.count },
        month: { unique: human.this_month.unique_count, views: human.this_month.count }
      }

      # ── Filters ───────────────────────────────────────────────────────────
      @date_range = params[:range].presence || "this_month"
      filtered = apply_date_range(human, @date_range)
      filtered = filtered.where(city: params[:city]) if params[:city].present?
      filtered = filtered.where(device_type: params[:device]) if params[:device].present?
      filtered = filtered.where("path ILIKE ?", "%#{sanitize_sql_like(params[:path])}%") if params[:path].present?

      @filter_active = params[:city].present? || params[:device].present? || params[:path].present? || !%w[this_month].include?(@date_range)

      # ── Filtered stats ────────────────────────────────────────────────────
      @filtered_unique = filtered.unique_count
      @filtered_views  = filtered.count

      @registered_count = filtered.where.not(user_id: nil).select(:user_id).distinct.count
      @anonymous_count  = filtered.where(user_id: nil).unique_count
      @bot_count_today  = Visit.where(bot: true).today.count

      @new_visitors       = filtered.where(new_visitor: true).unique_count
      @returning_visitors = filtered.where(new_visitor: false).unique_count

      durations = filtered.where.not(duration_seconds: nil).where("duration_seconds > 0")
      @avg_duration = durations.any? ? durations.average(:duration_seconds).to_i : 0

      # ── Top pages & cities ────────────────────────────────────────────────
      @top_pages = filtered
                     .group(:path)
                     .order(Arel.sql("COUNT(*) DESC"))
                     .limit(10)
                     .pluck(:path, Arel.sql("COUNT(*)"), Arel.sql("COUNT(DISTINCT visitor_token)"))
                     .map { |path, views, uniques| { path: path, views: views, uniques: uniques } }

      @top_cities = filtered
                      .where.not(city: [ nil, "" ])
                      .group(:city)
                      .order(Arel.sql("COUNT(DISTINCT visitor_token) DESC"))
                      .limit(10)
                      .pluck(:city, Arel.sql("COUNT(DISTINCT visitor_token)"))
                      .map { |city, count| { city: city, count: count } }

      # ── Device / Browser / OS breakdown ───────────────────────────────────
      @device_stats = filtered.where.not(device_type: nil)
                        .group(:device_type).order(Arel.sql("COUNT(*) DESC"))
                        .pluck(:device_type, Arel.sql("COUNT(DISTINCT visitor_token)"))
                        .map { |type, count| { type: type, count: count } }

      @browser_stats = filtered.where.not(browser: nil)
                         .group(:browser).order(Arel.sql("COUNT(*) DESC"))
                         .limit(6)
                         .pluck(:browser, Arel.sql("COUNT(DISTINCT visitor_token)"))
                         .map { |name, count| { name: name, count: count } }

      @os_stats = filtered.where.not(os: nil)
                    .group(:os).order(Arel.sql("COUNT(*) DESC"))
                    .limit(6)
                    .pluck(:os, Arel.sql("COUNT(DISTINCT visitor_token)"))
                    .map { |name, count| { name: name, count: count } }

      # ── Daily trend chart ─────────────────────────────────────────────────
      @daily_uniques = filtered
                         .group(Arel.sql("DATE(visited_at)"))
                         .order(Arel.sql("DATE(visited_at)"))
                         .pluck(Arel.sql("DATE(visited_at)"), Arel.sql("COUNT(DISTINCT visitor_token)"))
                         .map { |day, count| { day: day, count: count } }

      # ── Filter dropdown options (from actual data) ────────────────────────
      @available_cities = human.this_month.where.not(city: [ nil, "" ])
                            .group(:city).order(Arel.sql("COUNT(*) DESC")).limit(30)
                            .pluck(:city)

      @available_devices = human.this_month.where.not(device_type: nil)
                             .distinct.pluck(:device_type).sort

      @ga_realtime  = GoogleAnalyticsService.realtime_data
      @ga_reporting = GoogleAnalyticsService.reporting_data

      log_dashboard_view
    end

    def reports
      @reports = AnalyticsDailyReport.recent.limit(30)
    end

    private

    DATE_RANGES = {
      "today"      => -> { Time.current.beginning_of_day.. },
      "yesterday"  => -> { Time.current.yesterday.beginning_of_day..Time.current.yesterday.end_of_day },
      "this_week"  => -> { Time.current.beginning_of_week.. },
      "last_7"     => -> { 7.days.ago.beginning_of_day.. },
      "this_month" => -> { Time.current.beginning_of_month.. },
      "last_30"    => -> { 30.days.ago.beginning_of_day.. },
      "last_90"    => -> { 90.days.ago.beginning_of_day.. }
    }.freeze

    def apply_date_range(scope, range_key)
      if range_key == "custom" && params[:from].present? && params[:to].present?
        from = Date.parse(params[:from]).beginning_of_day rescue nil
        to   = Date.parse(params[:to]).end_of_day rescue nil
        return scope.where(visited_at: from..to) if from && to
      end

      range = DATE_RANGES[range_key]&.call || DATE_RANGES["this_month"].call
      scope.where(visited_at: range)
    end

    def log_dashboard_view
      filters = { range: @date_range, city: params[:city], device: params[:device], path: params[:path] }.compact_blank
      ga_total = @ga_reporting&.dig(:total_users)
      ga_realtime = @ga_realtime&.dig(:total)
      top_page = @top_pages.first
      top_city = @top_cities.first

      ANALYTICS_LOG.info(
        "DASHBOARD | user=#{current_user.id} | filters=#{filters.any? ? filters.to_json : "none"} | " \
        "today_unique=#{@stats[:today][:unique]} today_views=#{@stats[:today][:views]} | " \
        "week_unique=#{@stats[:week][:unique]} week_views=#{@stats[:week][:views]} | " \
        "month_unique=#{@stats[:month][:unique]} month_views=#{@stats[:month][:views]} | " \
        "filtered_unique=#{@filtered_unique} filtered_views=#{@filtered_views} | " \
        "registered=#{@registered_count} anonymous=#{@anonymous_count} bots_today=#{@bot_count_today} | " \
        "new=#{@new_visitors} returning=#{@returning_visitors} avg_duration=#{@avg_duration}s | " \
        "devices=#{@device_stats.map { |d| "#{d[:type]}:#{d[:count]}" }.join(",")} | " \
        "browsers=#{@browser_stats.map { |b| "#{b[:name]}:#{b[:count]}" }.join(",")} | " \
        "os=#{@os_stats.map { |o| "#{o[:name]}:#{o[:count]}" }.join(",")} | " \
        "top_page=#{top_page ? "#{top_page[:path]}(#{top_page[:uniques]})" : "none"} | " \
        "top_city=#{top_city ? "#{top_city[:city]}(#{top_city[:count]})" : "none"} | " \
        "ga_realtime=#{ga_realtime || "nil"} ga_total_users=#{ga_total || "nil"}"
      )
    rescue => e
      ANALYTICS_LOG.error "LOG_ERROR | #{e.class}: #{e.message}"
    end

    def require_super_admin
      redirect_to admin_root_path unless current_user.super_admin?
    end

    def sanitize_sql_like(string)
      string.to_s.gsub(/[%_\\]/) { |m| "\\#{m}" }
    end
  end
end
