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
  end
end
