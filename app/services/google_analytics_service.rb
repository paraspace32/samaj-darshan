require "google/apis/analyticsdata_v1beta"
require "googleauth"

class GoogleAnalyticsService
  PROPERTY_ID = "531385218"
  CACHE_KEY   = "ga_realtime_active_users"
  CACHE_TTL   = 60.seconds

  # Country code → flag emoji
  FLAG = ->(code) {
    return "🌍" if code.blank? || code == "(not set)"
    code.upcase.chars.map { |c| (c.ord + 127397).chr(Encoding::UTF_8) }.join
  }

  def self.realtime_data
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { fetch_from_api }
  end

  private

  def self.fetch_from_api
    credentials_json = ENV["GOOGLE_ANALYTICS_CREDENTIALS"]
    return nil if credentials_json.blank?

    service = Google::Apis::AnalyticsdataV1beta::AnalyticsDataService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(credentials_json),
      scope: "https://www.googleapis.com/auth/analytics.readonly"
    )

    request = Google::Apis::AnalyticsdataV1beta::RunRealtimeReportRequest.new(
      dimensions: [
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "country"),
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "countryId")
      ],
      metrics: [
        Google::Apis::AnalyticsdataV1beta::Metric.new(name: "activeUsers")
      ],
      limit: 5
    )

    response = service.run_property_realtime_report("properties/#{PROPERTY_ID}", request)

    total    = 0
    countries = []

    response.rows&.each do |row|
      country_name = row.dimension_values[0].value
      country_code = row.dimension_values[1].value
      count        = row.metric_values[0].value.to_i
      next if count.zero?

      total += count
      countries << {
        name:  country_name == "(not set)" ? "Unknown" : country_name,
        code:  country_code,
        flag:  FLAG.call(country_code),
        count: count
      }
    end

    {
      total:     total,
      countries: countries.sort_by { |c| -c[:count] }.first(4),
      fetched_at: Time.current
    }
  rescue StandardError => e
    Rails.logger.error "[GoogleAnalyticsService] #{e.class}: #{e.message}"
    nil
  end
end
