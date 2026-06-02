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
    elsif @region.nil? && @category.nil? && params[:page].blank? && params[:all].blank?
      # Auto-detect region from visitor IP on homepage (no explicit selection)
      @auto_region = detect_region_from_ip
      @news_items  = @news_items.where(region: @auto_region) if @auto_region
    end

    @regions = Region.active.ordered
    @categories = Category.active.ordered

    @page = [ params[:page].to_i, 1 ].max
    @is_home = @page == 1 && @region.nil? && @category.nil?
    @per_page = @is_home ? 5 : 12

    if @is_home
      # ── Education: degree news only on homepage ──
      @education_news = EducationPost.visible.category_degree_news
                                     .with_attached_cover_image.includes(:author).limit(5)

      # ── Jobs: split news-style (new_job_news) vs actual job listings ──────
      @job_news     = JobPost.visible.category_new_job_news
                             .with_attached_cover_image.includes(:author).limit(5)
      @job_listings = JobPost.visible.where.not(category: :new_job_news)
                             .with_attached_cover_image.includes(:author).limit(5)

      # ── Hero + Side stack: latest 10 across News, Education, Job ─────────
      # Combine latest news with hero-eligible education/job posts,
      # sort by published_at, and pick the top items for the hero area.
      hero_candidates = News.published.with_attached_cover_image
                            .includes(:region, :category, :author)
                            .order(published_at: :desc).limit(10).to_a

      hero_candidates += EducationPost.hero_eligible.includes(:author)
                                      .order(published_at: :desc).limit(10).to_a

      hero_candidates += JobPost.hero_eligible.includes(:author)
                                .order(published_at: :desc).limit(10).to_a

      hero_candidates.sort_by! { |item| -(item.published_at&.to_i || 0) }
      hero_candidates = hero_candidates.first(12)

      @featured = hero_candidates.first
      @featured_type = case @featured
      when EducationPost then :education
      when JobPost then :job
      else :news
      end

      @home_side_items = hero_candidates.drop(1).first(8)

      # Exclude hero items that are News records from the region section below
      excluded_news_ids = hero_candidates.first(9).select { |i| i.is_a?(News) }.map(&:id)
      remaining = @news_items.where.not(id: excluded_news_ids)
      @total_count = remaining.count
      @news_items  = remaining.offset(0).limit(@per_page)

      @trending = News.published.order(likes_count: :desc, comments_count: :desc)
                      .includes(:region, :category, :author).with_attached_cover_image
                      .limit(5)
      @latest_news_tab = News.published.includes(:region, :category, :author).with_attached_cover_image
                             .order(published_at: :desc).limit(5)
      @upcoming_webinar = Webinar.upcoming.includes(:host).with_attached_cover_image.first
      @latest_magazine  = Magazine.visible.includes(cover_image_attachment: :blob).first
      @biodata_count    = Biodata.visible.count

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
        *@home_side_items.map(&:id),      # globally-latest side stack
        *@news_items.map(&:id),           # region section items
        *@trending.map(&:id)
      ].compact.uniq

      # Only exclude the featured hero item from category sections — allow items
      # shown in side stack / region / trending to reappear under their category.
      hero_id = (@featured_type == :news ? @featured&.id : nil)
      category_exclude_ids = [ hero_id ].compact

      # Load ALL category news in ONE query, then group in Ruby.
      # This replaces N separate queries (one per category) with a single query.
      category_ids = @categories.map(&:id)
      all_category_news = News.published
                              .where(category_id: category_ids)
                              .where.not(id: category_exclude_ids)
                              .includes(:region, :category, :author)
                              .with_attached_cover_image
                              .order(published_at: :desc)
                              .to_a
      news_by_category = all_category_news.group_by(&:category_id)

      @category_sections = @categories.filter_map do |cat|
        items = (news_by_category[cat.id] || []).first(7)
        next if items.empty?

        { category: cat, items: items }
      end
    else
      @total_count = @news_items.count
      @news_items = @news_items.offset((@page - 1) * @per_page).limit(@per_page)
    end

    respond_to do |format|
      # Only serve Turbo Stream for pagination requests (infinite scroll).
      # Without this guard, post-login redirects to / match turbo_stream
      # (because Turbo sends Accept: text/vnd.turbo-stream.html) and return
      # stream actions instead of the full HTML page — breaking navigation.
      if params[:page].present?
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
      end
      format.html do
        # Skip HTTP caching for Turbo Frame requests — a 304 with no body
        # causes Turbo to show "Content missing" since it can't find the frame tag.
        unless turbo_frame_request?
          # Auto-region responses are per-visitor — never share in public cache
          fresh_when etag: cache_key_for_index, public: !logged_in? && @auto_region.nil?
        end
      end
    end
  end

  def show
    @news_item = News.published.find(params[:id])
    @login_gate = true unless logged_in?

    # Increment view counter — skip for admins, count everyone else
    News.update_counters(@news_item.id, views_count: 1) unless current_user&.admin_panel_access?

    # GA4 realtime API doesn't support per-page path filtering,
    # so we show site-wide active users count instead.
    @site_active_users = GoogleAnalyticsService.realtime_data&.dig(:total)

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

    # Sidebar widget: latest news (excl. current)
    @sidebar_news = News.published
                        .where.not(id: @news_item.id)
                        .includes(:region, :category)
                        .with_attached_cover_image
                        .order(published_at: :desc)
                        .limit(4)

    # Homepage-style sections shown below the article
    @education_news = EducationPost.visible.category_degree_news
                                   .with_attached_cover_image.includes(:author).limit(4)
    @job_news       = JobPost.visible.category_new_job_news
                             .with_attached_cover_image.includes(:author).limit(4)
    @job_listings   = JobPost.visible.where.not(category: :new_job_news)
                             .with_attached_cover_image.includes(:author).limit(6)

    latest_comment_at = @comments.first&.created_at
    fresh_when etag: [ @news_item, latest_comment_at ], last_modified: @news_item.updated_at, public: !logged_in? unless logged_in?
  end

  private

  def cache_key_for_index
    latest_news = News.published.maximum(:updated_at)
    latest_webinar = Webinar.published.maximum(:updated_at) if @is_home
    latest_edu = EducationPost.published.maximum(:updated_at) if @is_home
    latest_job = JobPost.published.category_new_job_news.maximum(:updated_at) if @is_home
    region_key = @region&.slug || @auto_region&.slug
    "news/index/v2/#{@page}/#{params[:slug]}/#{region_key}/#{latest_news&.to_i}/#{latest_webinar&.to_i}/#{latest_edu&.to_i}/#{latest_job&.to_i}/#{I18n.locale}"
  end

  def detect_region_from_ip
    visitor_region
  end
end
