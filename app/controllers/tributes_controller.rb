class TributesController < ApplicationController
  def index
    @tributes = Tribute.recent.includes(:flower_givers).with_attached_image
  end

  def show
    @tribute = Tribute.includes(flowers: :user).find(params[:id])
    @user_gave_flower = logged_in? && @tribute.flowers.exists?(user: current_user)
  end
end
