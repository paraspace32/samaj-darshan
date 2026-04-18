require "google/apis/analyticsdata_v1beta"
require "googleauth"

class GoogleAnalyticsService
  PROPERTY_ID = "531385218"

  REALTIME_CACHE_KEY  = "ga_realtime_active_users"
  REPORTING_CACHE_KEY = "ga_reporting_visitors"
  REALTIME_TTL        = 60.seconds
  REPORTING_TTL       = 6.hours

  # ISO 3166-1 alpha-2 → [lat, lng] centroid
  COUNTRY_CENTROIDS = {
    "AF" => [ 33.93, 67.71 ], "AL" => [ 41.15, 20.17 ], "DZ" => [ 28.03, 1.66 ],
    "AO" => [ -11.20, 17.87 ], "AR" => [ -38.42, -63.62 ], "AU" => [ -25.27, 133.78 ],
    "AT" => [ 47.52, 14.55 ], "AZ" => [ 40.14, 47.58 ], "BD" => [ 23.68, 90.35 ],
    "BE" => [ 50.50, 4.47 ], "BJ" => [ 9.31, 2.32 ], "BO" => [ -16.29, -63.59 ],
    "BR" => [ -14.24, -51.93 ], "BG" => [ 42.73, 25.49 ], "KH" => [ 12.57, 104.99 ],
    "CM" => [ 3.85, 11.50 ], "CA" => [ 56.13, -106.35 ], "CL" => [ -35.68, -71.54 ],
    "CN" => [ 35.86, 104.20 ], "CO" => [ 4.57, -74.30 ], "CD" => [ -4.04, 21.76 ],
    "CR" => [ 9.75, -83.75 ], "HR" => [ 45.10, 15.20 ], "CU" => [ 21.52, -77.78 ],
    "CZ" => [ 49.82, 15.47 ], "DK" => [ 56.26, 9.50 ], "DO" => [ 18.74, -70.16 ],
    "EC" => [ -1.83, -78.18 ], "EG" => [ 26.82, 30.80 ], "SV" => [ 13.79, -88.90 ],
    "ET" => [ 9.15, 40.49 ], "FI" => [ 61.92, 25.75 ], "FR" => [ 46.23, 2.21 ],
    "GA" => [ -0.80, 11.61 ], "DE" => [ 51.17, 10.45 ], "GH" => [ 7.95, -1.02 ],
    "GR" => [ 39.07, 21.82 ], "GT" => [ 15.78, -90.23 ], "GN" => [ 9.95, -11.31 ],
    "HT" => [ 18.97, -72.29 ], "HN" => [ 15.20, -86.24 ], "HK" => [ 22.40, 114.11 ],
    "HU" => [ 47.16, 19.50 ], "IN" => [ 20.59, 78.96 ], "ID" => [ -0.79, 113.92 ],
    "IR" => [ 32.43, 53.69 ], "IQ" => [ 33.22, 43.68 ], "IE" => [ 53.41, -8.24 ],
    "IL" => [ 31.05, 34.85 ], "IT" => [ 41.87, 12.57 ], "CI" => [ 7.54, -5.55 ],
    "JP" => [ 36.20, 138.25 ], "JO" => [ 30.59, 36.24 ], "KZ" => [ 48.02, 66.92 ],
    "KE" => [ -0.02, 37.91 ], "KW" => [ 29.31, 47.48 ], "LB" => [ 33.85, 35.86 ],
    "LY" => [ 26.34, 17.23 ], "MG" => [ -18.77, 46.87 ], "MY" => [ 4.21, 108.00 ],
    "ML" => [ 17.57, -3.99 ], "MX" => [ 23.63, -102.55 ], "MA" => [ 31.79, -7.09 ],
    "MZ" => [ -18.67, 35.53 ], "MM" => [ 21.92, 95.96 ], "NP" => [ 28.39, 84.12 ],
    "NL" => [ 52.13, 5.29 ], "NZ" => [ -40.90, 174.89 ], "NI" => [ 12.87, -85.21 ],
    "NE" => [ 17.61, 8.08 ], "NG" => [ 9.08, 8.68 ], "NO" => [ 60.47, 8.47 ],
    "OM" => [ 21.51, 55.92 ], "PK" => [ 30.38, 69.35 ], "PA" => [ 8.54, -80.78 ],
    "PG" => [ -6.31, 143.96 ], "PY" => [ -23.44, -58.44 ], "PE" => [ -9.19, -75.02 ],
    "PH" => [ 12.88, 121.77 ], "PL" => [ 51.92, 19.15 ], "PT" => [ 39.40, -8.22 ],
    "PR" => [ 18.22, -66.59 ], "QA" => [ 25.35, 51.18 ], "RO" => [ 45.94, 24.97 ],
    "RU" => [ 61.52, 105.32 ], "SA" => [ 23.89, 45.08 ], "SN" => [ 14.50, -14.45 ],
    "RS" => [ 44.02, 21.01 ], "SL" => [ 8.46, -11.78 ], "SO" => [ 5.15, 46.20 ],
    "ZA" => [ -30.56, 22.94 ], "SS" => [ 4.86, 31.57 ], "ES" => [ 40.46, -3.75 ],
    "LK" => [ 7.87, 80.77 ], "SD" => [ 12.86, 30.22 ], "SE" => [ 60.13, 18.64 ],
    "CH" => [ 46.82, 8.23 ], "SY" => [ 34.80, 38.99 ], "TW" => [ 23.70, 120.96 ],
    "TJ" => [ 38.86, 71.28 ], "TZ" => [ -6.37, 34.89 ], "TH" => [ 15.87, 100.99 ],
    "TG" => [ 8.62, 0.82 ], "TN" => [ 33.89, 9.54 ], "TR" => [ 38.96, 35.24 ],
    "TM" => [ 38.97, 59.56 ], "UG" => [ 1.37, 32.29 ], "UA" => [ 48.38, 31.17 ],
    "AE" => [ 23.42, 53.85 ], "GB" => [ 55.38, -3.44 ], "US" => [ 37.09, -95.71 ],
    "UY" => [ -32.52, -55.77 ], "UZ" => [ 41.38, 64.59 ], "VE" => [ 6.42, -66.59 ],
    "VN" => [ 14.06, 108.28 ], "YE" => [ 15.55, 48.52 ], "ZM" => [ -13.13, 27.85 ],
    "ZW" => [ -19.02, 29.15 ]
  }.freeze

  # Country code → flag emoji
  FLAG = ->(code) {
    return "🌍" if code.blank? || code == "(not set)"
    code.upcase.chars.map { |c| (c.ord + 127397).chr(Encoding::UTF_8) }.join
  }

  # ── Public API ────────────────────────────────────────────────────────────

  def self.realtime_data
    Rails.cache.fetch(REALTIME_CACHE_KEY, expires_in: REALTIME_TTL) { fetch_realtime }
  end

  def self.reporting_data
    Rails.cache.fetch(REPORTING_CACHE_KEY, expires_in: REPORTING_TTL) { fetch_reporting }
  end

  # ── Private ───────────────────────────────────────────────────────────────
  private

  def self.build_service
    credentials_json = ENV["GOOGLE_ANALYTICS_CREDENTIALS"]
    return nil if credentials_json.blank?

    service = Google::Apis::AnalyticsdataV1beta::AnalyticsDataService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(credentials_json),
      scope: "https://www.googleapis.com/auth/analytics.readonly"
    )
    service
  end

  def self.fetch_realtime
    service = build_service
    return nil unless service

    request = Google::Apis::AnalyticsdataV1beta::RunRealtimeReportRequest.new(
      dimensions: [
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "country"),
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "countryId")
      ],
      metrics: [
        Google::Apis::AnalyticsdataV1beta::Metric.new(name: "activeUsers")
      ],
      limit: 10
    )

    response = service.run_property_realtime_report("properties/#{PROPERTY_ID}", request)
    parse_countries(response.rows, metric_index: 0)
  rescue StandardError => e
    Rails.logger.error "[GA Realtime] #{e.class}: #{e.message}"
    nil
  end

  def self.fetch_reporting
    service = build_service
    return nil unless service

    # Total users (all time approximated as 3 years back)
    total_request = Google::Apis::AnalyticsdataV1beta::RunReportRequest.new(
      date_ranges: [ Google::Apis::AnalyticsdataV1beta::DateRange.new(start_date: "2020-01-01", end_date: "today") ],
      metrics: [ Google::Apis::AnalyticsdataV1beta::Metric.new(name: "totalUsers") ]
    )

    # Country breakdown (last 90 days for meaningful map data)
    country_request = Google::Apis::AnalyticsdataV1beta::RunReportRequest.new(
      date_ranges: [ Google::Apis::AnalyticsdataV1beta::DateRange.new(start_date: "90daysAgo", end_date: "today") ],
      dimensions: [
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "country"),
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "countryId")
      ],
      metrics: [ Google::Apis::AnalyticsdataV1beta::Metric.new(name: "totalUsers") ],
      order_bys: [
        Google::Apis::AnalyticsdataV1beta::OrderBy.new(
          metric: Google::Apis::AnalyticsdataV1beta::MetricOrderBy.new(metric_name: "totalUsers"),
          desc: true
        )
      ],
      limit: 50
    )

    total_response   = service.run_report("properties/#{PROPERTY_ID}", total_request)
    country_response = service.run_report("properties/#{PROPERTY_ID}", country_request)

    total_users = total_response.rows&.first&.metric_values&.first&.value.to_i
    country_data = parse_countries(country_response.rows, metric_index: 0)

    {
      total_users:   total_users,
      countries:     country_data[:countries],
      map_points:    country_data[:map_points],
      fetched_at:    Time.current
    }
  rescue StandardError => e
    Rails.logger.error "[GA Reporting] #{e.class}: #{e.message}"
    nil
  end

  def self.parse_countries(rows, metric_index:)
    total     = 0
    countries = []
    map_points = []

    rows&.each do |row|
      name  = row.dimension_values[0].value
      code  = row.dimension_values[1].value.upcase
      count = row.metric_values[metric_index].value.to_i
      next if count.zero? || name == "(not set)"

      total += count
      centroid = COUNTRY_CENTROIDS[code]

      countries << {
        name:  name,
        code:  code,
        flag:  FLAG.call(code),
        count: count
      }

      if centroid
        map_points << {
          lat:   centroid[0],
          lng:   centroid[1],
          name:  name,
          count: count
        }
      end
    end

    {
      total:      total,
      countries:  countries.first(5),
      map_points: map_points
    }
  end
end
