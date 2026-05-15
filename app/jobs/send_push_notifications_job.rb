class SendPushNotificationsJob < ApplicationJob
  queue_as :default

  # Enqueue with: SendPushNotificationsJob.perform_later(title:, body:, url:, image:, triggered_by_id:)
  def perform(title:, body:, url: nil, image: nil, triggered_by_id: nil)
    return if PushSubscription.none?

    results = FcmService.broadcast(title: title, body: body, url: url, image: image)

    PushNotificationLog.create!(
      title: title.to_s.truncate(255),
      url: url,
      total_subscribers: (results[:sent] + results[:failed] + results[:removed]),
      sent_count: results[:sent],
      failed_count: results[:failed],
      removed_count: results[:removed],
      triggered_by_id: triggered_by_id
    )

    Rails.logger.info "[SendPushNotificationsJob] #{results.inspect}"
  end
end
