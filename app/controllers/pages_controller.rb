class PagesController < ApplicationController
  def offline
  end

  def visitor_map
    @active_users  = GoogleAnalyticsService.realtime_data
    @visitor_stats = GoogleAnalyticsService.reporting_data
  end
end
