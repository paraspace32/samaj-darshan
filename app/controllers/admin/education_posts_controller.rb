module Admin
  class EducationPostsController < BaseController
    before_action :require_education_access
    before_action :set_education_post, only: [ :show, :edit, :update, :destroy, :publish ]

    def index
      @education_posts = EducationPost.includes(:author).order(created_at: :desc)
      @education_posts = @education_posts.where(status: params[:status]) if params[:status].present?
      @education_posts = @education_posts.where(category: params[:category]) if params[:category].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @education_posts = @education_posts.where("title_en ILIKE :q OR title_hi ILIKE :q", q: q)
      end
      @per_page = 20
      @page = [ params[:page].to_i, 1 ].max
      @total_count = @education_posts.count
      @education_posts = @education_posts.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show
    end

    def new
      @education_post = EducationPost.new(status: :draft)
    end

    def create
      @education_post = EducationPost.new(education_post_params)
      @education_post.author = current_user

      if @education_post.save
        redirect_to admin_education_post_path(@education_post), notice: "Education post created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @education_post.update(education_post_params)
        redirect_to admin_education_post_path(@education_post), notice: "Education post updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @education_post.destroy
      redirect_to admin_education_posts_path, notice: "Education post deleted."
    end

    def publish
      @education_post.publish!
      redirect_to admin_education_post_path(@education_post), notice: "Education post published."
    end

    private

    def set_education_post
      @education_post = EducationPost.find(params[:id])
    end

    def require_education_access
      raise Authorization::NotAuthorizedError unless current_user.can_manage_education?
    end

    def education_post_params
      params.require(:education_post).permit(
        :title_en, :title_hi, :content_en, :content_hi,
        :category, :organization_name, :exam_date,
        :registration_deadline, :official_url, :cover_image
      )
    end
  end
end
