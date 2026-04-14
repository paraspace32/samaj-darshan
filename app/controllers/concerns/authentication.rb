module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      session[:return_to] = request.fullpath
      redirect_to login_path, alert: I18n.t("flash.login_required")
    end
  end

  def require_active_account
    if logged_in? && current_user.account_blocked?
      reset_session
      redirect_to login_path, alert: I18n.t("flash.account_blocked")
    end
  end
end
