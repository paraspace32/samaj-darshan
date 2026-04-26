class PushSubscriptionsController < ApplicationController
  protect_from_forgery with: :null_session

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
      # For logged-in users: remove their older tokens on the same platform (1 token per user).
      # For anonymous users: don't deduplicate — generic Android/Chrome UA strings are identical
      # across many different devices, so UA-based deduplication deletes real subscribers.
      if current_user
        PushSubscription
          .where(platform: sub.platform, user_id: current_user.id)
          .where.not(id: sub.id)
          .destroy_all
      end
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
