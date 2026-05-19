class VisitsController < ApplicationController
  skip_after_action :record_visit

  def ping
    duration = params[:duration].to_i
    path = params[:path].to_s

    if duration.positive? && duration < 3600 && path.present?
      token = resolve_visitor_token
      visit = Visit.where(visitor_token: token, path: path)
                   .order(visited_at: :desc).first
      visit&.update_column(:duration_seconds, duration) if visit && visit.duration_seconds.nil?
    end

    head :no_content
  end

  private

  def resolve_visitor_token
    cookie = cookies[:_sd_visitor]
    if cookie.present? && !Visit.bot_user_agent?(request.user_agent)
      Digest::SHA256.hexdigest(cookie)
    else
      Visit.generate_token(request.remote_ip, request.user_agent)
    end
  end
end
