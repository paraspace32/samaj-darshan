module Admin
  class CacheController < BaseController
    CLEARABLE_KEYS = {
      "ga_realtime"  => "ga_realtime_active_users",
      "ga_reporting" => "ga_reporting_visitors"
    }.freeze

    def clear
      keys = params[:keys].present? ? params[:keys].split(",") : CLEARABLE_KEYS.keys

      cleared = keys.filter_map do |k|
        cache_key = CLEARABLE_KEYS[k.strip]
        next unless cache_key

        Rails.cache.delete(cache_key)
        k.strip
      end

      redirect_back fallback_location: admin_root_path,
                    notice: "Cache cleared: #{cleared.join(', ')}"
    end

    def ga_status
      raw = ENV["GOOGLE_ANALYTICS_CREDENTIALS"]

      status = {
        credential_present: raw.present?,
        credential_format:  raw.present? ? (raw.strip.start_with?("{") ? "raw JSON" : "base64") : "missing",
        credential_length:  raw&.length,
        realtime_cache:     Rails.cache.read("ga_realtime_active_users").inspect,
        reporting_cache:    Rails.cache.read("ga_reporting_visitors")&.slice(:total_users, :fetched_at)&.inspect || "nil"
      }

      # Try a live API call and capture any error
      begin
        result = GoogleAnalyticsService.send(:fetch_realtime)
        status[:api_test] = result ? "✅ Success — #{result[:total]} active users" : "❌ Returned nil (check logs)"
      rescue => e
        status[:api_test] = "❌ #{e.class}: #{e.message}"
      end

      # Also try decoding credentials to verify JSON is valid
      begin
        raw = ENV["GOOGLE_ANALYTICS_CREDENTIALS"]
        decoded = raw.strip.start_with?("{") ? raw : Base64.decode64(raw)
        parsed  = JSON.parse(decoded)
        status[:credential_email] = parsed["client_email"] || "not found"
        status[:credential_project] = parsed["project_id"] || "not found"
      rescue => e
        status[:credential_decode_error] = "#{e.class}: #{e.message}"
      end

      # Try building the service directly to catch auth errors
      begin
        svc = GoogleAnalyticsService.send(:build_service)
        status[:service_built] = svc ? "yes" : "no"
        if svc
          req = Google::Apis::AnalyticsdataV1beta::RunRealtimeReportRequest.new(
            metrics: [ Google::Apis::AnalyticsdataV1beta::Metric.new(name: "activeUsers") ]
          )
          resp = svc.run_property_realtime_report("properties/#{GoogleAnalyticsService::PROPERTY_ID}", req)
          status[:raw_api_response] = "rows: #{resp.rows&.length || 0}, total: #{resp.row_count}"
        end
      rescue => e
        status[:service_error] = "#{e.class}: #{e.message}"
      end

      render plain: status.map { |k, v| "#{k}: #{v}" }.join("\n"), content_type: "text/plain"
    end
  end
end
