class JobsController < ApplicationController
  def index
    @job_posts = JobPost.visible.with_attached_cover_image
    @job_posts = @job_posts.by_category(params[:category]) if params[:category].present?

    @per_page = 12
    @page = [ params[:page].to_i, 1 ].max
    @total_count = @job_posts.count
    @job_posts = @job_posts.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    @job_post = JobPost.published.find(params[:id])
    @liked    = current_user ? @job_post.likes.exists?(user: current_user) : false
    @comments = @job_post.comments.includes(:user).recent

    @related = JobPost.published
                      .where(category: @job_post.category)
                      .where.not(id: @job_post.id)
                      .includes(:author)
                      .with_attached_cover_image
                      .order(published_at: :desc)
                      .limit(5)

    @category_articles = JobPost.published
                                .where(category: @job_post.category)
                                .where.not(id: @job_post.id)
                                .includes(:author)
                                .with_attached_cover_image
                                .order(published_at: :desc)
                                .limit(6)

    @trending_articles = JobPost.published
                                .where.not(id: @job_post.id)
                                .includes(:author)
                                .order(@job_post.category_new_job_news? ? { likes_count: :desc, comments_count: :desc, published_at: :desc } : { published_at: :desc })
                                .limit(5)
  end
end
