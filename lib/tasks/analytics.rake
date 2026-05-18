namespace :analytics do
  desc "Run daily Visit vs GA comparison report (defaults to yesterday)"
  task daily_report: :environment do
    date = ENV.fetch("DATE", Date.yesterday.to_s)
    AnalyticsDailyReportJob.perform_now(date)
  end
end
