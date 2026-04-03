class LikesController < ApplicationController
  before_action :require_login
  before_action :require_active_account
  before_action :set_article

  def toggle
    existing = @article.likes.find_by(user: current_user)

    if existing
      existing.destroy
    else
      @article.likes.create(user: current_user)
    end

    redirect_to article_path(@article, anchor: "like-section")
  end

  private

  def set_article
    @article = Article.published.find(params[:article_id])
  end
end
