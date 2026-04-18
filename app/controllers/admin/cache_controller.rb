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
  end
end
