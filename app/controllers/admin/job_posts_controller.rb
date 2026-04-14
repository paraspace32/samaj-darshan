module Admin
  class JobPostsController < BaseController
    before_action :require_jobs_access
    before_action :set_job_post, only: [ :show, :edit, :update, :destroy, :publish ]

    def index
      @job_posts = JobPost.includes(:author).order(created_at: :desc)
      @job_posts = @job_posts.where(status: params[:status]) if params[:status].present?
      @job_posts = @job_posts.where(category: params[:category]) if params[:category].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @job_posts = @job_posts.where("title_en ILIKE :q OR title_hi ILIKE :q OR company_name ILIKE :q", q: q)
      end
      @per_page = 20
      @page = [ params[:page].to_i, 1 ].max
      @total_count = @job_posts.count
      @job_posts = @job_posts.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show
    end

    def new
      @job_post = JobPost.new(status: :draft)
    end

    def create
      @job_post = JobPost.new(job_post_params)
      @job_post.author = current_user

      if @job_post.save
        redirect_to admin_job_post_path(@job_post), notice: "Job post created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @job_post.update(job_post_params)
        redirect_to admin_job_post_path(@job_post), notice: "Job post updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @job_post.destroy
      redirect_to admin_job_posts_path, notice: "Job post deleted."
    end

    def publish
      @job_post.publish!
      redirect_to admin_job_post_path(@job_post), notice: "Job post published."
    end

    private

    def set_job_post
      @job_post = JobPost.find(params[:id])
    end

    def require_jobs_access
      raise Authorization::NotAuthorizedError unless current_user.can_manage_jobs?
    end

    def job_post_params
      params.require(:job_post).permit(
        :title_en, :title_hi, :description_en, :description_hi,
        :category, :company_name, :location, :deadline,
        :application_url, :cover_image
      )
    end
  end
end
