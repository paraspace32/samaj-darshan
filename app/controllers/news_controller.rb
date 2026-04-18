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

    @is_home = @page == 1 && @region.nil? && @category.nil?

    if @is_home
      # Determine the overall latest item across news, education posts, and job posts
      @education_posts = EducationPost.visible.with_attached_cover_image.includes(:author).limit(6)
      @job_posts = JobPost.visible.with_attached_cover_image.includes(:author).limit(6)

      latest_news_item = @news_items.first
      latest_education = @education_posts.first
      latest_job = @job_posts.first

      candidates = [
        (latest_news_item ? [ latest_news_item, latest_news_item.published_at, :news ] : nil),
        (latest_education ? [ latest_education, latest_education.published_at, :education ] : nil),
        (latest_job ? [ latest_job, latest_job.published_at, :job ] : nil)
      ].compact

      if candidates.any?
        overall_latest = candidates.max_by { |_, pub_at, _| pub_at || Time.at(0) }
        @featured = overall_latest[0]
        @featured_type = overall_latest[2]
      end

      remaining = @news_items.where.not(id: @featured_type == :news ? @featured&.id : nil)
      @total_count = remaining.count
      @news_items = remaining.offset(0).limit(@per_page)

      @trending = News.published.order(likes_count: :desc, comments_count: :desc)
                      .includes(:region, :category, :author).with_attached_cover_image
                      .limit(5)
      @upcoming_webinar = Webinar.upcoming.includes(:host).with_attached_cover_image.first
      @latest_magazine = Magazine.visible.includes(cover_image_attachment: :blob).first

      @active_users = GoogleAnalyticsService.realtime_data

      shown_ids = [ (@featured_type == :news ? @featured&.id : nil), *@news_items.first(3).map(&:id), *@trending.map(&:id) ].compact.uniq
      @category_sections = @categories.filter_map do |cat|
        items = News.published.where(category: cat).where.not(id: shown_ids)
                    .includes(:region, :category, :author).with_attached_cover_image
                    .order(published_at: :desc).limit(6)
        next if items.empty?

        shown_ids.concat(items.map(&:id))
        { category: cat, items: items.to_a }
      end
    else
      @total_count = @news_items.count
      @news_items = @news_items.offset((@page - 1) * @per_page).limit(@per_page)
    end

    fresh_when etag: cache_key_for_index, public: !logged_in?
  end

  def show
    @news_item = News.published.find(params[:id])
    @comments = @news_item.comments.includes(:user).recent
    @liked = current_user ? @news_item.likes.exists?(user: current_user) : false
    @related = News.published
                   .where(region: @news_item.region)
                   .where.not(id: @news_item.id)
                   .includes(:region, :category, :author)
                   .with_attached_cover_image
                   .order(published_at: :desc)
                   .limit(5)

    latest_comment_at = @comments.first&.created_at
    fresh_when etag: [ @news_item, latest_comment_at ], last_modified: @news_item.updated_at, public: !logged_in? unless logged_in?
  end

  private

  def cache_key_for_index
    latest_news = News.published.maximum(:updated_at)
    latest_webinar = Webinar.published.maximum(:updated_at) if @is_home
    latest_edu = EducationPost.published.maximum(:updated_at) if @is_home
    latest_job = JobPost.published.maximum(:updated_at) if @is_home
    "news/index/#{@page}/#{params[:slug]}/#{latest_news&.to_i}/#{latest_webinar&.to_i}/#{latest_edu&.to_i}/#{latest_job&.to_i}/#{I18n.locale}"
  end
end
