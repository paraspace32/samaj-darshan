class ArticlesController < ApplicationController
  def index
    @articles = Article.feed

    if params[:slug].present?
      if request.path.start_with?("/region")
        @region = Region.find_by!(slug: params[:slug])
        @articles = @articles.where(region: @region)
      elsif request.path.start_with?("/category")
        @category = Category.find_by!(slug: params[:slug])
        @articles = @articles.where(category: @category)
      end
    end

    @regions = Region.active.ordered
    @categories = Category.active.ordered

    @per_page = 12
    @page = [ params[:page].to_i, 1 ].max

    if @page == 1 && @region.nil? && @category.nil?
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
    @article = Article.published.find(params[:id])
    @related = Article.published
                      .where(region: @article.region)
                      .where.not(id: @article.id)
                      .order(published_at: :desc)
                      .limit(5)
  end
end
