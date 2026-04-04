class LikesController < ApplicationController
  before_action :require_login
  before_action :require_active_account
  before_action :set_likeable

  def toggle
    existing = @likeable.likes.find_by(user: current_user)

    if existing
      existing.destroy
    else
      @likeable.likes.create(user: current_user)
    end

    redirect_to news_path(@likeable, anchor: "like-section")
  end

  private

  def set_likeable
    @likeable = News.published.find(params[:news_id])
  end
end
