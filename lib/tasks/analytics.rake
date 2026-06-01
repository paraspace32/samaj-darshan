namespace :analytics do
  desc "Run daily Visit vs GA comparison report (defaults to yesterday)"
  task daily_report: :environment do
    date = ENV.fetch("DATE", Date.yesterday.to_s)
    AnalyticsDailyReportJob.perform_now(date)
  end

  desc "Validate analytics: compare Visit tracking vs GA for recent days"
  task validate: :environment do
    days = (ENV["DAYS"] || 7).to_i
    puts "=" * 90
    puts "ANALYTICS VALIDATION — Last #{days} days (Visit tracking vs Google Analytics)"
    puts "=" * 90
    puts format("%-12s | %8s %8s | %8s %8s %8s | %8s %8s | %s",
      "Date", "V.Users", "V.Views", "GA.Users", "GA.Sess", "GA.Views", "UserΔ%", "ViewΔ%", "Status")
    puts "-" * 90

    alerts = []
    missing_reports = []
    missing_ga = []

    days.times do |i|
      date = Date.yesterday - i
      report = AnalyticsDailyReport.find_by(date: date)

      if report.nil?
        missing_reports << date
        puts format("%-12s | %8s %8s | %8s %8s %8s | %8s %8s | %s",
          date, "-", "-", "-", "-", "-", "-", "-", "MISSING REPORT")
        next
      end

      if report.ga_users.nil?
        missing_ga << date
      end

      status = if report.ga_users.nil?
        "NO GA DATA"
      elsif report.alert?
        alerts << date
        "⚠ ALERT (>30%)"
      else
        "OK"
      end

      puts format("%-12s | %8s %8s | %8s %8s %8s | %8s %8s | %s",
        date,
        report.visit_unique || "-", report.visit_views || "-",
        report.ga_users || "-", report.ga_sessions || "-", report.ga_pageviews || "-",
        report.user_delta_pct ? "#{report.user_delta_pct}%" : "-",
        report.view_delta_pct ? "#{report.view_delta_pct}%" : "-",
        status)
    end

    puts "-" * 90

    # Live GA check for yesterday
    puts "\n📊 Live GA query for yesterday (#{Date.yesterday})..."
    ga_live = GoogleAnalyticsService.daily_users(start_date: Date.yesterday)
    if ga_live
      puts "  GA Users: #{ga_live[:users]}, Sessions: #{ga_live[:sessions]}, Pageviews: #{ga_live[:pageviews]}, New Users: #{ga_live[:new_users]}"

      report = AnalyticsDailyReport.find_by(date: Date.yesterday)
      if report&.ga_users
        if report.ga_users == ga_live[:users]
          puts "  ✅ Stored GA data matches live query"
        else
          puts "  ⚠️  Stored GA users (#{report.ga_users}) differs from live (#{ga_live[:users]}) — GA data can update retroactively"
        end
      end
    else
      puts "  ❌ Could not fetch GA data — check GOOGLE_ANALYTICS_CREDENTIALS"
    end

    # Visit tracking check for yesterday
    puts "\n📈 Live Visit query for yesterday..."
    range = Date.yesterday.beginning_of_day..Date.yesterday.end_of_day
    human = Visit.human.where(visited_at: range)
    live_unique = human.unique_count
    live_views = human.count
    puts "  Visit Unique: #{live_unique}, Views: #{live_views}"

    report = AnalyticsDailyReport.find_by(date: Date.yesterday)
    if report
      if report.visit_unique == live_unique
        puts "  ✅ Stored visit data matches live query"
      else
        puts "  ⚠️  Stored visit unique (#{report.visit_unique}) differs from live (#{live_unique})"
      end
    end

    # Summary
    puts "\n" + "=" * 90
    puts "SUMMARY"
    puts "  Reports checked: #{days}"
    puts "  Missing reports: #{missing_reports.size}#{missing_reports.any? ? " (#{missing_reports.join(', ')})" : ''}"
    puts "  Missing GA data: #{missing_ga.size}#{missing_ga.any? ? " (#{missing_ga.join(', ')})" : ''}"
    puts "  Alerts (>30% delta): #{alerts.size}#{alerts.any? ? " (#{alerts.join(', ')})" : ''}"
    puts "=" * 90
  end

  desc "Flag behavioral bots for a date (defaults to yesterday)"
  task flag_bots: :environment do
    date = ENV.fetch("DATE", Date.yesterday.to_s)
    flagged = FlagBotVisitorsJob.perform_now(date)
    puts "Flagged #{flagged} visits as bot"
  end
end
