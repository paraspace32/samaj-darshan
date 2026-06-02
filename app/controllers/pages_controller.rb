class PagesController < ApplicationController
  def offline
  end

  def visitor_map
    @active_users  = GoogleAnalyticsService.realtime_data
    @visitor_stats = GoogleAnalyticsService.reporting_data
    render partial: "shared/visitor_map",
           locals: { realtime: @active_users, reporting: @visitor_stats }
  end
end
