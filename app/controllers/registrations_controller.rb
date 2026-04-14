class RegistrationsController < ApplicationController
  layout "auth"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :user
    @user.status = :active

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: t("signup.success")
    else
      if @user.errors[:phone].any? && User.exists?(phone: @user.phone)
        flash.now[:alert] = t("signup.already_registered")
      end
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :phone, :email, :password, :password_confirmation)
  end
end
