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
  end
end
