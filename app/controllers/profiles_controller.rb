class ProfilesController < ApplicationController
  before_action :require_login

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # Only update password if the user filled in the new password field
    user_params = profile_params
    if user_params[:password].blank?
      user_params = user_params.except(:password, :password_confirmation)
    end

    if @user.update(user_params)
      redirect_to edit_profile_path, notice: t("profile.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
  end
end
