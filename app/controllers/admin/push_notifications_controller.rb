class Admin::PushNotificationsController < Admin::BaseController
  # GET /admin/push_notifications
  def index
    @total_subscriptions = PushSubscription.count
    @web_count           = PushSubscription.web.count
    @pwa_count           = PushSubscription.pwa.count
    @android_count       = PushSubscription.on_android.count
    @ios_count           = PushSubscription.on_ios.count
    @desktop_count       = PushSubscription.on_desktop.count
    @anonymous_count     = PushSubscription.anonymous.count
    @logged_in_count     = PushSubscription.logged_in.count
    @recent              = PushSubscription.order(created_at: :desc).limit(10)
  end

  # POST /admin/push_notifications/send
  def send_notification
    title = params[:title].presence || t("brand.name")
    url   = params[:url].presence

    SendPushNotificationsJob.perform_later(title: title, body: nil, url: url, image: nil)
    redirect_to admin_push_notifications_path,
                notice: "Push notification queued for #{PushSubscription.count} subscribers."
  rescue => e
    Rails.logger.error "[Push] admin send failed: #{e.class}: #{e.message}"
    redirect_to admin_push_notifications_path,
                alert: "Failed to queue notification: #{e.message.truncate(120)}"
  end

  # POST /admin/news/:id/push  (called from news show page)
  def send_for_news
    @news_item = News.find(params[:news_id])

    unless @news_item.published?
      return redirect_to admin_news_path(@news_item), alert: "Article must be published first."
    end

    title = @news_item.display_title.truncate(80, separator: " ")
    url   = news_url(@news_item)

    SendPushNotificationsJob.perform_later(title: title, body: nil, url: url, image: nil)
    redirect_to admin_news_path(@news_item),
                notice: "Push notification queued for #{PushSubscription.count} subscribers."
  rescue => e
    Rails.logger.error "[Push] admin send_for_news failed: #{e.class}: #{e.message}"
    redirect_to admin_news_path(@news_item),
                alert: "Failed to queue notification: #{e.message.truncate(120)}"
  end
end
