class MagazineController < ApplicationController
  def index
    @articles = Article.magazine_feed
    @categories = Category.active.ordered

    if params[:category].present?
      @category = Category.find_by(slug: params[:category])
      @articles = @articles.where(category: @category) if @category
    end

    @per_page = 12
    @page = [params[:page].to_i, 1].max

    if @page == 1 && @category.nil?
      @featured = @articles.first
      remaining = @articles.where.not(id: @featured&.id)
      @total_count = remaining.count
      @articles = remaining.offset(0).limit(@per_page)
    else
      @total_count = @articles.count
      @articles = @articles.offset((@page - 1) * @per_page).limit(@per_page)
    end
  end

  def show
    @article = Article.published.magazine_only.find(params[:id])
    @comments = @article.comments.includes(:user).recent
    @liked = current_user ? @article.likes.exists?(user: current_user) : false
    @related = Article.published.magazine_only
                      .where.not(id: @article.id)
                      .order(published_at: :desc)
                      .limit(4)
  end
end
