namespace :analytics do
  desc "Run daily Visit vs GA comparison report (defaults to yesterday)"
  task daily_report: :environment do
    date = ENV.fetch("DATE", Date.yesterday.to_s)
    AnalyticsDailyReportJob.perform_now(date)
  end

  desc "Flag behavioral bots for a date (defaults to yesterday)"
  task flag_bots: :environment do
    date = ENV.fetch("DATE", Date.yesterday.to_s)
    flagged = FlagBotVisitorsJob.perform_now(date)
    puts "Flagged #{flagged} visits as bot"
  end
end
