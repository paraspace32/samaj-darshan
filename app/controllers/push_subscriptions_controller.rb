class PushSubscriptionsController < ApplicationController
  protect_from_forgery with: :null_session

  # POST /push_subscriptions/log_error  — receives JS-side errors for server logging
  def log_error
    Rails.logger.error("[Push] JS error | ip=#{request.remote_ip} msg=#{params[:message]} | #{params[:detail]}")
    head :ok
  end

  # POST /push_subscriptions
  def create
    token = params[:token].to_s.strip
    if token.blank?
      Rails.logger.warn("[Push] subscribe rejected: blank token | ip=#{request.remote_ip} user=#{current_user&.id || "anon"}")
      return head :bad_request
    end

    sub        = PushSubscription.find_or_initialize_by(token: token)
    is_new     = sub.new_record?
    sub.user   = current_user
    sub.platform = params[:platform].presence || "web"
    sub.browser  = params[:browser].presence

    if sub.save
      action_taken = is_new ? "created" : "refreshed"
      Rails.logger.info("[Push] subscribe #{action_taken} | id=#{sub.id} user=#{current_user&.id || "anon"} platform=#{sub.platform} ip=#{request.remote_ip} browser=#{sub.browser&.slice(0, 80)}")

      # For logged-in users: remove their older tokens on the same platform (1 token per user).
      # For anonymous users: don't deduplicate — generic Android/Chrome UA strings are identical
      # across many different devices, so UA-based deduplication deletes real subscribers.
      if current_user
        removed = PushSubscription
          .where(platform: sub.platform, user_id: current_user.id)
          .where.not(id: sub.id)
          .destroy_all
        if removed.any?
          Rails.logger.info("[Push] removed #{removed.size} stale token(s) for user=#{current_user.id} platform=#{sub.platform} | old_ids=#{removed.map(&:id).inspect}")
        end
      end

      total = PushSubscription.count
      Rails.logger.info("[Push] total subscribers: #{total}")
      head :ok
    else
      Rails.logger.error("[Push] subscribe failed to save | user=#{current_user&.id || "anon"} ip=#{request.remote_ip} errors=#{sub.errors.full_messages.inspect}")
      head :unprocessable_entity
    end
  end

  # DELETE /push_subscriptions
  def destroy
    token = params[:token].to_s.strip
    sub   = PushSubscription.find_by(token: token)
    if sub
      sub.destroy
      Rails.logger.info("[Push] unsubscribed | id=#{sub.id} user=#{sub.user_id || "anon"} platform=#{sub.platform} ip=#{request.remote_ip}")
    else
      Rails.logger.warn("[Push] unsubscribe: token not found | ip=#{request.remote_ip}")
    end
    total = PushSubscription.count
    Rails.logger.info("[Push] total subscribers: #{total}")
    head :ok
  end
end
