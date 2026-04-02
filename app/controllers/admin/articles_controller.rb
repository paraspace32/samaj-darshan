module Admin
  class ArticlesController < BaseController
    before_action :set_article, only: [ :show, :edit, :update, :destroy, :publish, :approve, :reject, :submit_for_review ]
    before_action :set_form_collections, only: [ :new, :create, :edit, :update ]
    before_action :require_content_creator, only: [ :new, :create ]
    before_action :require_editor_access, only: [ :publish, :approve, :reject ]
    before_action :authorize_edit, only: [ :edit, :update ]
    before_action :authorize_delete, only: [ :destroy ]

    def index
      @articles = Article.includes(:region, :category, :author).order(created_at: :desc)
      @articles = @articles.where(status: params[:status]) if params[:status].present?
      @articles = @articles.where(region_id: params[:region_id]) if params[:region_id].present?
      @articles = @articles.where(category_id: params[:category_id]) if params[:category_id].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @articles = @articles.where("title_en ILIKE :q OR title_hi ILIKE :q", q: q)
      end
      @per_page = 20
      @page = [ params[:page].to_i, 1 ].max
      @total_count = @articles.count
      @articles = @articles.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show
    end

    def new
      @article = Article.new(status: :draft, article_type: :news)
    end

    def create
      @article = Article.new(article_params)
      @article.author = current_user

      if @article.save
        redirect_to admin_article_path(@article), notice: "Article created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if params[:remove_image_id].present?
        @article.images.find_by(id: params[:remove_image_id])&.purge
        redirect_to edit_admin_article_path(@article), notice: "Image removed."
        return
      end

      if @article.update(article_params)
        redirect_to admin_article_path(@article), notice: "Article updated successfully."
      else
        set_form_collections
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy
      redirect_to admin_articles_path, notice: "Article deleted."
    end

    def publish
      @article.publish!
      redirect_to admin_article_path(@article), notice: "Article published."
    end

    def approve
      @article.approve!
      redirect_to admin_article_path(@article), notice: "Article approved."
    end

    def reject
      @article.reject!(params[:rejection_reason])
      redirect_to admin_article_path(@article), notice: "Article rejected."
    end

    def submit_for_review
      @article.submit_for_review!
      redirect_to admin_article_path(@article), notice: "Article submitted for review."
    end

    private

    def set_article
      @article = Article.find(params[:id])
    end

    def set_form_collections
      @regions = Region.active.ordered
      @categories = Category.active.ordered
    end

    def authorize_edit
      raise Authorization::NotAuthorizedError unless current_user.can_edit_article?(@article)
    end

    def authorize_delete
      raise Authorization::NotAuthorizedError unless current_user.can_delete_articles?
    end

    def article_params
      params.require(:article).permit(
        :title_en, :title_hi, :content_en, :content_hi,
        :region_id, :category_id, :article_type, :cover_image,
        images: []
      )
    end
  end
end
