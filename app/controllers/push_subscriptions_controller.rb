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

    sub              = PushSubscription.find_or_initialize_by(token: token)
    is_new           = sub.new_record?
    sub.user         = current_user
    sub.platform     = params[:platform].presence     || "web"
    sub.display_mode = params[:display_mode].presence || "browser"
    sub.os           = params[:os].presence           || "unknown"
    sub.browser      = params[:browser].presence

    if sub.save
      action_taken = is_new ? "created" : "refreshed"
      Rails.logger.info(
        "[Push] subscribe #{action_taken} | " \
        "id=#{sub.id} " \
        "user=#{current_user&.id || "anon"} " \
        "identity=#{sub.identity_label} " \    # e.g. pwa/android/standalone
        "ip=#{request.remote_ip} " \
        "browser=#{sub.browser&.slice(0, 80)}"
      )

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

      log_subscriber_summary
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
      Rails.logger.info("[Push] unsubscribed | id=#{sub.id} user=#{sub.user_id || "anon"} identity=#{sub.identity_label} ip=#{request.remote_ip}")
    else
      Rails.logger.warn("[Push] unsubscribe: token not found | ip=#{request.remote_ip}")
    end
    log_subscriber_summary
    head :ok
  end

  private

  # Logs a full breakdown of current subscribers by segment — written after
  # every subscribe / unsubscribe so the live log always shows the current state.
  def log_subscriber_summary
    total   = PushSubscription.count
    web     = PushSubscription.web.count
    pwa     = PushSubscription.pwa.count
    android = PushSubscription.on_android.count
    ios     = PushSubscription.on_ios.count
    desktop = PushSubscription.on_desktop.count
    anon    = PushSubscription.anonymous.count
    logged  = PushSubscription.logged_in.count

    Rails.logger.info(
      "[Push] subscribers: total=#{total} | " \
      "platform: web=#{web} pwa=#{pwa} | " \
      "os: android=#{android} ios=#{ios} desktop=#{desktop} | " \
      "auth: logged_in=#{logged} anonymous=#{anon}"
    )
  end
end
