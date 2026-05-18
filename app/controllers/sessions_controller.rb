class SessionsController < ApplicationController
  layout "auth"

  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
  end

  def create
    if rate_limited?(:otp_login, limit: 10, period: 1.minute)
      render json: { error: t("auth.too_many_attempts") }, status: :too_many_requests
      return
    end

    phone = params[:phone].to_s.strip.gsub(/\D/, "")
    id_token = params[:firebase_id_token].to_s

    unless phone.match?(/\A[6-9]\d{9}\z/) && id_token.present?
      render json: { error: t("auth.invalid_request") }, status: :unprocessable_entity
      return
    end

    verified_phone = if Rails.env.test?
      phone
    else
      verify_firebase_token(id_token, phone)
    end

    unless verified_phone
      render json: { error: t("auth.verification_failed") }, status: :unprocessable_entity
      return
    end

    user = User.find_by(phone: phone)

    if user
      if user.account_blocked?
        render json: { error: t("flash.blocked_login") }, status: :forbidden
        return
      end

      session[:user_id] = user.id
      return_to = session.delete(:return_to)
      redirect_url = return_to || (user.admin_panel_access? ? admin_root_path : root_path)
      render json: { redirect_to: redirect_url }
    else
      session[:verified_phone] = phone
      render json: { needs_name: true }
    end
  end

  def set_name
    phone = session.delete(:verified_phone)
    name = params[:name].to_s.strip

    unless phone.present? && name.present?
      Rails.logger.warn "[set_name] Missing data — phone=#{phone.present?} name=#{name.present?}"
      render json: { error: t("auth.name_required") }, status: :unprocessable_entity
      return
    end

    user = User.new(phone: phone, name: name, role: :user, status: :active)
    unless user.save
      Rails.logger.warn "[set_name] Save failed — #{user.errors.full_messages}"
      render json: { error: user.errors.full_messages.first || t("auth.signup_failed") }, status: :unprocessable_entity
      return
    end

    session[:user_id] = user.id
    render json: { redirect_to: root_path }
  end

  def destroy
    reset_session
    redirect_to login_path, notice: t("flash.logged_out")
  end

  private

  def redirect_if_logged_in
    if logged_in?
      redirect_to current_user.admin_panel_access? ? admin_root_path : root_path
    end
  end

  def verify_firebase_token(id_token, expected_phone)
    uri = URI("https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=#{firebase_api_key}")
    response = Net::HTTP.post(uri, { idToken: id_token }.to_json, "Content-Type" => "application/json")

    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    user_info = data.dig("users", 0)
    return nil unless user_info

    firebase_phone = user_info["phoneNumber"].to_s.gsub(/\A\+91/, "")
    return nil unless firebase_phone == expected_phone

    firebase_phone
  rescue StandardError
    nil
  end

  def firebase_api_key
    Rails.application.credentials.dig(:firebase, :api_key) || ENV["FIREBASE_API_KEY"]
  end

  def rate_limited?(key, limit:, period:)
    counter_key = "rate_limit_#{key}"
    reset_key = "rate_limit_#{key}_reset"
    now = Time.current.to_i

    if session[reset_key].nil? || session[reset_key] < now
      session[counter_key] = 1
      session[reset_key] = now + period.to_i
      false
    else
      session[counter_key] = (session[counter_key] || 0) + 1
      session[counter_key] > limit
    end
  end
end
