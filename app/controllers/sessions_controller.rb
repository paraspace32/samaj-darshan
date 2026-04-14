class SessionsController < ApplicationController
  layout "auth"

  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
  end

  def create
    user = User.find_by(phone: params[:phone])

    if user&.authenticate(params[:password])
      if user.account_blocked?
        flash.now[:alert] = t("flash.blocked_login")
        render :new, status: :unprocessable_entity
      else
        session[:user_id] = user.id
        return_to = session.delete(:return_to)
        redirect_to return_to || (user.admin_panel_access? ? admin_root_path : root_path), notice: t("flash.welcome_back", name: user.name)
      end
    else
      flash.now[:alert] = t("flash.invalid_credentials")
      render :new, status: :unprocessable_entity
    end
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
end
