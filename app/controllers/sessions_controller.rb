class SessionsController < ApplicationController
  layout "auth"

  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
  end

  def check
    if rate_limited?(:phone_check, limit: 10, period: 1.minute)
      return render json: { error: "too_many_requests" }, status: :too_many_requests
    end

    phone = params[:phone].to_s.strip.gsub(/\D/, "")
    exists = User.exists?(phone: phone)
    render json: { exists: exists }
  end

  def create
    phone = params[:phone].to_s.strip.gsub(/\D/, "")
    user = User.find_by(phone: phone)

    if user
      if user.authenticate(params[:password])
        if user.account_blocked?
          flash.now[:alert] = t("flash.blocked_login")
          render :new, status: :unprocessable_entity
        else
          session[:user_id] = user.id
          return_to = session.delete(:return_to)
          redirect_to return_to || (user.admin_panel_access? ? admin_root_path : root_path), notice: t("flash.welcome_back", name: user.name), status: :see_other
        end
      else
        flash.now[:alert] = t("flash.invalid_credentials")
        render :new, status: :unprocessable_entity
      end
    else
      new_user = User.new(
        name: params[:name].to_s.strip,
        phone: phone,
        password: params[:password],
        password_confirmation: params[:password],
        role: :user,
        status: :active
      )

      if new_user.save
        session[:user_id] = new_user.id
        redirect_to root_path, notice: t("signup.success"), status: :see_other
      else
        flash.now[:alert] = new_user.errors.full_messages.first
        render :new, status: :unprocessable_entity
      end
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
