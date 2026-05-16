class VisitsController < ApplicationController
  skip_after_action :record_visit

  def ping
    token = Visit.generate_token(request.remote_ip, request.user_agent)
    duration = params[:duration].to_i
    path = params[:path].to_s

    if duration.positive? && duration < 3600 && path.present?
      visit = Visit.where(visitor_token: token, path: path)
                   .order(visited_at: :desc).first
      visit&.update_column(:duration_seconds, duration) if visit && visit.duration_seconds.nil?
    end

    head :no_content
  end
end
