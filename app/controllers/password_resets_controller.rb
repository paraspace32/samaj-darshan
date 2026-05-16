class PasswordResetsController < ApplicationController
  layout "auth"

  def new
  end

  def update
    if rate_limited?(:password_reset, limit: 5, period: 15.minutes)
      flash.now[:alert] = t("password_reset.too_many_attempts")
      return render :new, status: :too_many_requests
    end

    phone = params[:phone].to_s.strip.gsub(/\D/, "")
    id_token = params[:firebase_id_token].to_s

    if phone.blank? || id_token.blank?
      flash.now[:alert] = t("password_reset.invalid_request")
      return render :new, status: :unprocessable_entity
    end

    user = User.find_by(phone: phone)
    unless user
      flash.now[:alert] = t("password_reset.phone_not_found")
      return render :new, status: :unprocessable_entity
    end

    unless verify_firebase_token(id_token, phone)
      flash.now[:alert] = t("password_reset.verification_failed")
      return render :new, status: :unprocessable_entity
    end

    password = params[:password].to_s
    if password.length < 6
      flash.now[:alert] = t("password_reset.password_too_short")
      return render :new, status: :unprocessable_entity
    end

    if user.update(password: password, password_confirmation: password)
      session[:user_id] = user.id
      redirect_to root_path, notice: t("password_reset.success"), status: :see_other
    else
      flash.now[:alert] = user.errors.full_messages.first
      render :new, status: :unprocessable_entity
    end
  end

  private

  def verify_firebase_token(id_token, expected_phone)
    require "net/http"
    require "json"

    uri = URI("https://identitytoolkit.googleapis.com/v1/accounts:lookup")
    creds = Rails.application.credentials.firebase || {}
    api_key = creds[:api_key] || ENV["FIREBASE_API_KEY"]
    uri.query = URI.encode_www_form(key: api_key)

    response = Net::HTTP.post(uri, { idToken: id_token }.to_json, "Content-Type" => "application/json")
    return false unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    firebase_phone = data.dig("users", 0, "phoneNumber")
    return false unless firebase_phone.present?

    normalized = firebase_phone.gsub(/\A\+91/, "")
    normalized == expected_phone
  rescue StandardError => e
    Rails.logger.warn "[PasswordReset] Firebase token verification failed: #{e.message}"
    false
  end
end
