require "google/apis/analyticsdata_v1beta"
require "googleauth"

class GoogleAnalyticsService
  PROPERTY_ID = "531385218"

  REALTIME_CACHE_KEY  = "ga_realtime_active_users"
  REPORTING_CACHE_KEY = "ga_reporting_visitors"
  REALTIME_TTL        = 60.seconds
  REPORTING_TTL       = 15.minutes

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
    Rails.cache.fetch(REALTIME_CACHE_KEY, expires_in: REALTIME_TTL, skip_nil: true) { fetch_realtime }
  end

  def self.reporting_data
    Rails.cache.fetch(REPORTING_CACHE_KEY, expires_in: REPORTING_TTL, skip_nil: true) { fetch_reporting }
  end

  # ── Private ───────────────────────────────────────────────────────────────
  private

  def self.build_service
    raw = ENV["GOOGLE_ANALYTICS_CREDENTIALS"]
    return nil if raw.blank?

    # Support both raw JSON and base64-encoded JSON
    credentials_json = raw.strip.start_with?("{") ? raw : Base64.decode64(raw)

    service = Google::Apis::AnalyticsdataV1beta::AnalyticsDataService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(credentials_json),
      scope: "https://www.googleapis.com/auth/analytics.readonly"
    )
    service
  end

  # City name → [lat, lng]
  CITY_COORDINATES = {
    # India
    "Mumbai" => [ 19.076, 72.877 ], "Delhi" => [ 28.704, 77.102 ], "New Delhi" => [ 28.614, 77.210 ],
    "Bangalore" => [ 12.972, 77.594 ], "Bengaluru" => [ 12.972, 77.594 ],
    "Hyderabad" => [ 17.385, 78.487 ], "Chennai" => [ 13.083, 80.270 ],
    "Kolkata" => [ 22.573, 88.363 ], "Pune" => [ 18.520, 73.856 ],
    "Ahmedabad" => [ 23.023, 72.572 ], "Jaipur" => [ 26.912, 75.787 ],
    "Surat" => [ 21.170, 72.831 ], "Lucknow" => [ 26.847, 80.947 ],
    "Kanpur" => [ 26.449, 80.331 ], "Nagpur" => [ 21.146, 79.088 ],
    "Indore" => [ 22.718, 75.857 ], "Thane" => [ 19.218, 72.978 ],
    "Bhopal" => [ 23.259, 77.413 ], "Visakhapatnam" => [ 17.688, 83.218 ],
    "Patna" => [ 25.594, 85.137 ], "Vadodara" => [ 22.307, 73.181 ],
    "Ghaziabad" => [ 28.670, 77.420 ], "Ludhiana" => [ 30.901, 75.857 ],
    "Agra" => [ 27.176, 78.008 ], "Nashik" => [ 19.997, 73.791 ],
    "Faridabad" => [ 28.408, 77.317 ], "Meerut" => [ 28.984, 77.706 ],
    "Rajkot" => [ 22.303, 70.802 ], "Varanasi" => [ 25.317, 82.974 ],
    "Srinagar" => [ 34.083, 74.797 ], "Aurangabad" => [ 19.877, 75.340 ],
    "Amritsar" => [ 31.634, 74.872 ], "Prayagraj" => [ 25.435, 81.846 ],
    "Allahabad" => [ 25.435, 81.846 ], "Ranchi" => [ 23.344, 85.310 ],
    "Coimbatore" => [ 11.017, 76.956 ], "Jabalpur" => [ 23.181, 79.987 ],
    "Gwalior" => [ 26.228, 78.174 ], "Vijayawada" => [ 16.506, 80.648 ],
    "Jodhpur" => [ 26.255, 73.023 ], "Madurai" => [ 9.925, 78.120 ],
    "Raipur" => [ 21.251, 81.630 ], "Kochi" => [ 9.931, 76.267 ],
    "Chandigarh" => [ 30.734, 76.779 ], "Guwahati" => [ 26.144, 91.736 ],
    "Mysuru" => [ 12.295, 76.639 ], "Mysore" => [ 12.295, 76.639 ],
    "Noida" => [ 28.535, 77.391 ], "Gurugram" => [ 28.459, 77.027 ],
    "Gurgaon" => [ 28.459, 77.027 ], "Dehradun" => [ 30.316, 78.032 ],
    "Kota" => [ 25.182, 75.839 ], "Udaipur" => [ 24.585, 73.712 ],
    "Bhubaneswar" => [ 20.296, 85.825 ], "Mangaluru" => [ 12.914, 74.856 ],
    "Mangalore" => [ 12.914, 74.856 ], "Kozhikode" => [ 11.259, 75.782 ],
    "Thiruvananthapuram" => [ 8.524, 76.936 ], "Jammu" => [ 32.727, 74.857 ],
    "Siliguri" => [ 26.727, 88.397 ], "Jamshedpur" => [ 22.802, 86.185 ],
    "Durgapur" => [ 23.480, 87.320 ], "Gorakhpur" => [ 26.760, 83.373 ],
    "Bikaner" => [ 28.022, 73.313 ], "Ajmer" => [ 26.450, 74.639 ],
    "Jhansi" => [ 25.448, 78.569 ], "Tiruchirappalli" => [ 10.790, 78.703 ],
    "Salem" => [ 11.664, 78.146 ], "Tiruppur" => [ 11.108, 77.341 ],
    "Bareilly" => [ 28.347, 79.419 ], "Aligarh" => [ 27.884, 78.078 ],
    "Warangal" => [ 17.977, 79.598 ], "Kolhapur" => [ 16.705, 74.243 ],
    "Ujjain" => [ 23.182, 75.784 ], "Saharanpur" => [ 29.964, 77.547 ],
    "Hubli" => [ 15.360, 75.124 ], "Dharwad" => [ 15.460, 75.008 ],
    "Belgaum" => [ 15.865, 74.505 ], "Bellary" => [ 15.139, 76.921 ],
    "Nanded" => [ 19.160, 77.322 ], "Gulbarga" => [ 17.330, 76.820 ],
    "Tirunelveli" => [ 8.727, 77.694 ], "Guntur" => [ 16.307, 80.436 ],
    "Kurnool" => [ 15.828, 78.037 ], "Davanagere" => [ 14.465, 75.921 ],
    "Damoh" => [ 23.833, 79.450 ], "Sagar" => [ 23.838, 78.737 ],
    "Satna" => [ 24.600, 80.833 ], "Rewa" => [ 24.530, 81.296 ],
    "Katni" => [ 23.833, 80.400 ], "Chhindwara" => [ 22.057, 78.938 ],
    "Shivpuri" => [ 25.423, 77.659 ], "Morena" => [ 26.499, 77.998 ],
    "Bhind" => [ 26.557, 78.781 ], "Vidisha" => [ 23.524, 77.809 ],
    "Hoshangabad" => [ 22.750, 77.716 ], "Betul" => [ 21.913, 77.895 ],
    "Seoni" => [ 22.087, 79.536 ], "Balaghat" => [ 21.813, 80.186 ],
    "Mandla" => [ 22.600, 80.383 ], "Dindori" => [ 22.943, 81.078 ],
    "Bokaro" => [ 23.667, 86.150 ], "Gaya" => [ 24.797, 85.007 ],
    "Akola" => [ 20.706, 77.007 ], "Jalgaon" => [ 21.002, 75.562 ],
    "Malegaon" => [ 20.561, 74.526 ], "Sangli" => [ 16.854, 74.564 ],
    "Solapur" => [ 17.686, 75.906 ], "Latur" => [ 18.407, 76.574 ],
    "Dhule" => [ 20.901, 74.777 ], "Navi Mumbai" => [ 19.033, 73.030 ],
    "Amravati" => [ 20.932, 77.750 ], "Bhiwandi" => [ 19.296, 73.059 ],
    "Jalandhar" => [ 31.326, 75.576 ], "Rohtak" => [ 28.895, 76.606 ],
    "Panipat" => [ 29.387, 76.970 ], "Karnal" => [ 29.686, 76.990 ],
    "Hisar" => [ 29.151, 75.722 ], "Ambala" => [ 30.378, 76.776 ],
    "Firozabad" => [ 27.150, 78.395 ], "Muzaffarnagar" => [ 29.473, 77.704 ],
    # Global cities
    "New York" => [ 40.713, -74.006 ], "Los Angeles" => [ 34.052, -118.244 ],
    "Chicago" => [ 41.878, -87.630 ], "Houston" => [ 29.760, -95.370 ],
    "Phoenix" => [ 33.448, -112.074 ], "Philadelphia" => [ 39.953, -75.165 ],
    "San Antonio" => [ 29.425, -98.494 ], "San Diego" => [ 32.715, -117.157 ],
    "Dallas" => [ 32.776, -96.797 ], "San Jose" => [ 37.339, -121.895 ],
    "London" => [ 51.507, -0.128 ], "Birmingham" => [ 52.480, -1.902 ],
    "Manchester" => [ 53.481, -2.244 ], "Toronto" => [ 43.653, -79.383 ],
    "Vancouver" => [ 49.283, -123.121 ], "Montreal" => [ 45.501, -73.567 ],
    "Sydney" => [ -33.868, 151.209 ], "Melbourne" => [ -37.813, 144.963 ],
    "Brisbane" => [ -27.470, 153.021 ], "Perth" => [ -31.950, 115.860 ],
    "Singapore" => [ 1.352, 103.820 ], "Dubai" => [ 25.205, 55.270 ],
    "Abu Dhabi" => [ 24.453, 54.377 ], "Riyadh" => [ 24.688, 46.722 ],
    "Jeddah" => [ 21.543, 39.173 ], "Karachi" => [ 24.861, 67.010 ],
    "Lahore" => [ 31.558, 74.359 ], "Islamabad" => [ 33.729, 73.094 ],
    "Dhaka" => [ 23.811, 90.412 ], "Chittagong" => [ 22.356, 91.784 ],
    "Kathmandu" => [ 27.717, 85.314 ], "Colombo" => [ 6.927, 79.862 ],
    "Nairobi" => [ -1.286, 36.817 ], "Johannesburg" => [ -26.204, 28.047 ],
    "Cape Town" => [ -33.925, 18.424 ], "Cairo" => [ 30.044, 31.236 ],
    "Lagos" => [ 6.524, 3.379 ], "Accra" => [ 5.603, -0.187 ],
    "Paris" => [ 48.857, 2.347 ], "Berlin" => [ 52.520, 13.405 ],
    "Madrid" => [ 40.416, -3.703 ], "Rome" => [ 41.902, 12.496 ],
    "Amsterdam" => [ 52.374, 4.890 ], "Moscow" => [ 55.751, 37.616 ],
    "Beijing" => [ 39.906, 116.391 ], "Shanghai" => [ 31.228, 121.474 ],
    "Guangzhou" => [ 23.129, 113.264 ], "Shenzhen" => [ 22.543, 114.058 ],
    "Tokyo" => [ 35.689, 139.692 ], "Osaka" => [ 34.694, 135.502 ],
    "Seoul" => [ 37.566, 126.978 ], "Bangkok" => [ 13.756, 100.502 ],
    "Kuala Lumpur" => [ 3.140, 101.687 ], "Jakarta" => [ -6.208, 106.846 ],
    "Manila" => [ 14.599, 120.984 ], "Taipei" => [ 25.048, 121.514 ],
    "Hong Kong" => [ 22.319, 114.170 ], "Ho Chi Minh City" => [ 10.823, 106.630 ],
    "Hanoi" => [ 21.028, 105.834 ], "Yangon" => [ 16.867, 96.195 ],
    "Colombo" => [ 6.927, 79.862 ], "Kabul" => [ 34.528, 69.172 ],
    "Tehran" => [ 35.694, 51.422 ], "Baghdad" => [ 33.341, 44.401 ],
    "Ankara" => [ 39.921, 32.854 ], "Istanbul" => [ 41.013, 28.948 ]
  }.freeze

  def self.fetch_realtime
    service = build_service
    return nil unless service

    request = Google::Apis::AnalyticsdataV1beta::RunRealtimeReportRequest.new(
      dimensions: [
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "city"),
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "country"),
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "countryId")
      ],
      metrics: [
        Google::Apis::AnalyticsdataV1beta::Metric.new(name: "activeUsers")
      ],
      limit: 20
    )

    response = service.run_property_realtime_report("properties/#{PROPERTY_ID}", request)
    parse_cities(response.rows, metric_index: 0)
  rescue StandardError => e
    Rails.logger.error "[GA Realtime] #{e.class}: #{e.message}"
    nil
  end

  def self.fetch_reporting
    service = build_service
    return nil unless service

    total_request = Google::Apis::AnalyticsdataV1beta::RunReportRequest.new(
      date_ranges: [ Google::Apis::AnalyticsdataV1beta::DateRange.new(start_date: "2020-01-01", end_date: "today") ],
      metrics: [ Google::Apis::AnalyticsdataV1beta::Metric.new(name: "totalUsers") ]
    )

    city_request = Google::Apis::AnalyticsdataV1beta::RunReportRequest.new(
      date_ranges: [ Google::Apis::AnalyticsdataV1beta::DateRange.new(start_date: "90daysAgo", end_date: "today") ],
      dimensions: [
        Google::Apis::AnalyticsdataV1beta::Dimension.new(name: "city"),
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
      limit: 100
    )

    total_response = service.run_property_report("properties/#{PROPERTY_ID}", total_request)
    city_response  = service.run_property_report("properties/#{PROPERTY_ID}", city_request)

    total_users = total_response.rows&.first&.metric_values&.first&.value.to_i
    city_data   = parse_cities(city_response.rows, metric_index: 0)

    {
      total_users: total_users,
      countries:   city_data[:countries],
      map_points:  city_data[:map_points],
      fetched_at:  Time.current
    }
  rescue StandardError => e
    Rails.logger.error "[GA Reporting] #{e.class}: #{e.message}"
    nil
  end

  def self.parse_cities(rows, metric_index:)
    total      = 0
    countries  = {}
    map_points = []

    rows&.each do |row|
      city    = row.dimension_values[0].value
      country = row.dimension_values[1].value
      code    = row.dimension_values[2].value.upcase
      count   = row.metric_values[metric_index].value.to_i
      next if count.zero? || city == "(not set)" || country == "(not set)"

      total += count

      # Aggregate by country for the pills
      countries[code] ||= { name: country, code: code, flag: FLAG.call(code), count: 0 }
      countries[code][:count] += count

      # Prefer city-level coords; fall back to country centroid for unknown cities
      coords = CITY_COORDINATES[city] || COUNTRY_CENTROIDS[code]
      if coords
        map_points << { lat: coords[0], lng: coords[1], name: city, country: country, count: count }
      else
        Rails.logger.info "[GA] No coords for city=#{city} country=#{country} (#{code})"
      end
    end

    {
      total:      total,
      countries:  countries.values.sort_by { |c| -c[:count] }.first(8),
      map_points: map_points
    }
  end

  # Keep for backwards compat
  def self.parse_countries(rows, metric_index:)
    parse_cities(rows, metric_index: metric_index)
  end
end
