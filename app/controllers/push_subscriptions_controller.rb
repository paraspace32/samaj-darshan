class PushSubscriptionsController < ApplicationController
  # POST /push_subscriptions/log_error  — receives JS-side errors for server logging
  def log_error
    Rails.logger.error("[PushNotification] Client error: #{params[:message]} | #{params[:detail]}")
    head :ok
  end

  # POST /push_subscriptions
  def create
    token = params[:token].to_s.strip
    return head :bad_request if token.blank?

    sub = PushSubscription.find_or_initialize_by(token: token)
    sub.user     = current_user
    sub.platform = params[:platform].presence || "web"
    sub.browser  = params[:browser].presence

    if sub.save
      head :ok
    else
      head :unprocessable_entity
    end
  end

  # DELETE /push_subscriptions
  def destroy
    token = params[:token].to_s.strip
    PushSubscription.find_by(token: token)&.destroy
    head :ok
  end
end
