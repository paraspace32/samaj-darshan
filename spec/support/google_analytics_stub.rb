RSpec.configure do |config|
  config.before do
    allow(GoogleAnalyticsService).to receive(:realtime_data).and_return({ total: 5, countries: [], map_points: [] })
    allow(GoogleAnalyticsService).to receive(:reporting_data).and_return({ total_users: 100, total_events: 500 })
  end
end
