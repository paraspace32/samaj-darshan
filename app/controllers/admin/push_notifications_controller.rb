class Admin::PushNotificationsController < Admin::BaseController
  # GET /admin/push_notifications
  def index
    @total_subscriptions = PushSubscription.count
    @web_count           = PushSubscription.web.count
    @recent              = PushSubscription.order(created_at: :desc).limit(10)
  end

  # POST /admin/push_notifications/send
  def send_notification
    title = params[:title].presence || t("brand.name")
    body  = params[:body].presence
    url   = params[:url].presence
    image = params[:image].presence

    return redirect_to admin_push_notifications_path, alert: "Body is required." if body.blank?

    SendPushNotificationsJob.perform_later(title: title, body: body, url: url, image: image)
    redirect_to admin_push_notifications_path, notice: "Push notification queued for #{PushSubscription.count} subscribers."
  end

  # POST /admin/news/:id/push  (called from news show page)
  def send_for_news
    @news_item = News.find(params[:news_id])

    unless @news_item.published?
      return redirect_to admin_news_path(@news_item), alert: "Article must be published first."
    end

    title = @news_item.display_title.truncate(80, separator: " ")
    body  = ActionController::Base.helpers.strip_tags(@news_item.display_content).truncate(120, separator: " ")
    url   = Rails.application.routes.url_helpers.news_url(@news_item, host: request.host_with_port)
    image = @news_item.cover_image.attached? ? Rails.application.routes.url_helpers.url_for(@news_item.cover_image) : nil

    SendPushNotificationsJob.perform_later(title: title, body: body, url: url, image: image)
    redirect_to admin_news_path(@news_item), notice: "Push notification queued for #{PushSubscription.count} subscribers."
  end
end
