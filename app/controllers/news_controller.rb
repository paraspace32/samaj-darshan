class NewsController < ApplicationController
  def index
    @news_items = News.feed

    if params[:slug].present?
      if request.path.start_with?("/region")
        @region = Region.find_by!(slug: params[:slug])
        @news_items = @news_items.where(region: @region)
      elsif request.path.start_with?("/category")
        @category = Category.find_by!(slug: params[:slug])
        @news_items = @news_items.where(category: @category)
      end
    end

    @regions = Region.active.ordered
    @categories = Category.active.ordered

    @per_page = 12
    @page = [ params[:page].to_i, 1 ].max

    if @page == 1 && @region.nil? && @category.nil?
      @featured = @news_items.first
      remaining = @news_items.where.not(id: @featured&.id)
      @total_count = remaining.count
      @news_items = remaining.offset(0).limit(@per_page)
    else
      @total_count = @news_items.count
      @news_items = @news_items.offset((@page - 1) * @per_page).limit(@per_page)
    end

    fresh_when etag: cache_key_for_index, public: !logged_in?
  end

  def show
    @news_item = News.published.find(params[:id])

    fresh_when @news_item, public: !logged_in? if !logged_in?

    @comments = @news_item.comments.includes(:user).recent
    @liked = current_user ? @news_item.likes.exists?(user: current_user) : false
    @related = News.published
                   .where(region: @news_item.region)
                   .where.not(id: @news_item.id)
                   .includes(:region, :category, :author)
                   .with_attached_cover_image
                   .order(published_at: :desc)
                   .limit(5)
  end

  private

  def cache_key_for_index
    latest = News.published.maximum(:updated_at)
    "news/index/#{@page}/#{params[:slug]}/#{latest&.to_i}/#{I18n.locale}"
  end
end
