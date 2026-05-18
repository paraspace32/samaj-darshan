module Trackable
  extend ActiveSupport::Concern

  included do
    after_action :record_visit
  end

  private

  def record_visit
    return unless request.format.html?
    return if request.path.start_with?("/admin", "/up", "/manifest", "/service-worker", "/firebase-messaging")

    RecordVisitJob.perform_later(
      ip:         request.remote_ip,
      user_agent: request.user_agent,
      path:       request.path,
      referrer:   request.referrer,
      user_id:    current_user&.id,
      visited_at: Time.current.iso8601
    )
  end
end
