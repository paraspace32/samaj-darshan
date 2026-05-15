class FlowersController < ApplicationController
  before_action :require_login
  before_action :require_active_account
  before_action :set_tribute

  def create
    flower = @tribute.flowers.build(user: current_user)

    if flower.save
      redirect_to tribute_path(@tribute), notice: t("tributes.flower_given")
    else
      redirect_to tribute_path(@tribute), alert: t("tributes.flower_already_given")
    end
  end

  def destroy
    flower = @tribute.flowers.find_by(user: current_user)
    flower&.destroy
    redirect_to tribute_path(@tribute), notice: t("tributes.flower_removed")
  end

  private

  def set_tribute
    @tribute = Tribute.find(params[:tribute_id])
  end
end
