class SendPushNotificationsJob < ApplicationJob
  queue_as :default

  # Enqueue with: SendPushNotificationsJob.perform_later(title:, body:, url:, image:)
  def perform(title:, body:, url: nil, image: nil)
    return if PushSubscription.none?

    results = FcmService.broadcast(title: title, body: body, url: url, image: image)
    Rails.logger.info "[SendPushNotificationsJob] #{results.inspect}"
  end
end
