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
      # ── Education: degree news only on homepage ──
      @education_news = EducationPost.visible.category_degree_news
                                     .with_attached_cover_image.includes(:author).limit(4)

      # ── Jobs: split news-style (new_job_news) vs actual job listings ──────
      @job_news     = JobPost.visible.category_new_job_news
                             .with_attached_cover_image.includes(:author).limit(4)
      @job_listings = JobPost.visible.where.not(category: :new_job_news)
                             .with_attached_cover_image.includes(:author).limit(6)

      # ── Determine featured item (newest across news / edu-news / job-news) ─
      latest_news_item = @news_items.first
      latest_education = @education_news.first
      latest_job       = @job_news.first

      candidates = [
        (latest_news_item ? [ latest_news_item, latest_news_item.published_at, :news ]      : nil),
        (latest_education ? [ latest_education, latest_education.published_at, :education ] : nil),
        (latest_job       ? [ latest_job,       latest_job.published_at,       :job ]       : nil)
      ].compact

      if candidates.any?
        overall_latest = candidates.max_by { |_, pub_at, _| pub_at || Time.at(0) }
        @featured      = overall_latest[0]
        @featured_type = overall_latest[2]
      end

      remaining    = @news_items.where.not(id: @featured_type == :news ? @featured&.id : nil)
      @total_count = remaining.count
      @news_items  = remaining.offset(0).limit(@per_page)

      @trending = News.published.order(likes_count: :desc, comments_count: :desc)
                      .includes(:region, :category, :author).with_attached_cover_image
                      .limit(5)
      @latest_news_tab = News.published.includes(:region, :category, :author).with_attached_cover_image
                             .order(published_at: :desc).limit(5)
      @upcoming_webinar = Webinar.upcoming.includes(:host).with_attached_cover_image.first
      @latest_magazine  = Magazine.visible.includes(cover_image_attachment: :blob).first

      begin
        @active_users  = GoogleAnalyticsService.realtime_data
        @visitor_stats = GoogleAnalyticsService.reporting_data
      rescue => e
        Rails.logger.error "[GA] #{e.class}: #{e.message}"
        @active_users = @visitor_stats = nil
      end

      # ── De-duplicate: exclude ALL latest-news-grid items from category sections ─
      # This ensures category sections always show distinct content from the bottom grid
      shown_ids = [
        (@featured_type == :news ? @featured&.id : nil),
        *@news_items.map(&:id),           # full bottom-grid batch, not just first 3
        *@trending.map(&:id)
      ].compact.uniq

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

    respond_to do |format|
      format.turbo_stream do
        total_pages = (@total_count.to_f / @per_page).ceil
        has_more    = @page < total_pages
        next_url    = has_more ? url_for(request.query_parameters.merge(page: @page + 1)) : nil
        render turbo_stream: [
          turbo_stream.append("news-grid-mobile",  partial: "news/news_mobile_item",  collection: @news_items, as: :news_item),
          turbo_stream.append("news-grid-desktop", partial: "news/news_desktop_item", collection: @news_items, as: :news_item),
          turbo_stream.replace("news-sentinel",    partial: "news/news_sentinel",     locals: { has_more: has_more, next_url: next_url })
        ]
      end
      format.html do
        fresh_when etag: cache_key_for_index, public: !logged_in?
      end
    end
  end

  def show
    @news_item = News.published.find(params[:id])

    # Increment view counter — skip for admins, count everyone else
    News.update_counters(@news_item.id, views_count: 1) unless current_user&.admin_panel_access?

    # Live reader counts from GA
    # @active_readers → people on THIS article right now (per-page filter)
    # @site_active_users → people on the whole site right now (always shows something)
    @active_readers   = GoogleAnalyticsService.active_readers(request.path)
    @site_active_users = begin
      GoogleAnalyticsService.realtime_data&.dig(:total)
    rescue
      nil
    end

    @comments = @news_item.comments.includes(:user).recent
    @liked = current_user ? @news_item.likes.exists?(user: current_user) : false
    @related = News.published
                   .where(region: @news_item.region)
                   .where.not(id: @news_item.id)
                   .includes(:region, :category, :author)
                   .with_attached_cover_image
                   .order(published_at: :desc)
                   .limit(5)

    @category_articles = News.published
                             .where(category: @news_item.category)
                             .where.not(id: @news_item.id)
                             .includes(:region, :category, :author)
                             .with_attached_cover_image
                             .order(published_at: :desc)
                             .limit(6)

    @trending_articles = News.published
                             .where.not(id: @news_item.id)
                             .includes(:region, :category)
                             .order(views_count: :desc, likes_count: :desc)
                             .limit(5)

    latest_comment_at = @comments.first&.created_at
    fresh_when etag: [ @news_item, latest_comment_at ], last_modified: @news_item.updated_at, public: !logged_in? unless logged_in?
  end

  private

  def cache_key_for_index
    latest_news = News.published.maximum(:updated_at)
    latest_webinar = Webinar.published.maximum(:updated_at) if @is_home
    latest_edu = EducationPost.published.maximum(:updated_at) if @is_home
    latest_job = JobPost.published.category_new_job_news.maximum(:updated_at) if @is_home
    "news/index/v2/#{@page}/#{params[:slug]}/#{latest_news&.to_i}/#{latest_webinar&.to_i}/#{latest_edu&.to_i}/#{latest_job&.to_i}/#{I18n.locale}"
  end
end
