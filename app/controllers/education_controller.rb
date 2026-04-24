class EducationController < ApplicationController
  def index
    @education_posts = EducationPost.visible.with_attached_cover_image
    @education_posts = @education_posts.by_category(params[:category]) if params[:category].present?

    @per_page = 12
    @page = [ params[:page].to_i, 1 ].max
    @total_count = @education_posts.count
    @education_posts = @education_posts.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    @education_post = EducationPost.published.find(params[:id])
    @comments = @education_post.comments.includes(:user).recent
    @liked = current_user ? @education_post.likes.exists?(user: current_user) : false
    @site_active_users = begin
      GoogleAnalyticsService.realtime_data&.dig(:total)
    rescue
      nil
    end

    @related = EducationPost.published
                            .where(category: @education_post.category)
                            .where.not(id: @education_post.id)
                            .includes(:author)
                            .with_attached_cover_image
                            .order(published_at: :desc)
                            .limit(5)

    @category_articles = EducationPost.published
                                      .where(category: @education_post.category)
                                      .where.not(id: @education_post.id)
                                      .includes(:author)
                                      .with_attached_cover_image
                                      .order(published_at: :desc)
                                      .limit(6)

    @trending_articles = EducationPost.published
                                      .where.not(id: @education_post.id)
                                      .includes(:author)
                                      .order(likes_count: :desc, comments_count: :desc, published_at: :desc)
                                      .limit(5)

    # Sidebar + cross-content: latest general news
    @sidebar_news = News.published
                        .includes(:region, :category)
                        .with_attached_cover_image
                        .order(published_at: :desc)
                        .limit(4)
  end
end
