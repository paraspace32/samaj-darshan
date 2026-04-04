module Admin
  class NewsController < BaseController
    before_action :set_news_item, only: [ :show, :edit, :update, :destroy, :publish, :approve, :reject, :submit_for_review ]
    before_action :set_form_collections, only: [ :new, :create, :edit, :update ]
    before_action :require_content_creator, only: [ :new, :create ]
    before_action :require_editor_access, only: [ :publish, :approve, :reject ]
    before_action :authorize_edit, only: [ :edit, :update ]
    before_action :authorize_delete, only: [ :destroy ]

    def index
      @news_items = News.includes(:region, :category, :author).order(created_at: :desc)
      @news_items = @news_items.where(status: params[:status]) if params[:status].present?
      @news_items = @news_items.where(region_id: params[:region_id]) if params[:region_id].present?
      @news_items = @news_items.where(category_id: params[:category_id]) if params[:category_id].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @news_items = @news_items.where("title_en ILIKE :q OR title_hi ILIKE :q", q: q)
      end
      @per_page = 20
      @page = [params[:page].to_i, 1].max
      @total_count = @news_items.count
      @news_items = @news_items.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show
    end

    def new
      @news_item = News.new(status: :draft)
    end

    def create
      @news_item = News.new(news_params)
      @news_item.author = current_user

      if @news_item.save
        redirect_to admin_news_path(@news_item), notice: "News created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if params[:remove_image_id].present?
        @news_item.images.find_by(id: params[:remove_image_id])&.purge
        redirect_to edit_admin_news_path(@news_item), notice: "Image removed."
        return
      end

      if @news_item.update(news_params)
        redirect_to admin_news_path(@news_item), notice: "News updated successfully."
      else
        set_form_collections
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @news_item.destroy
      redirect_to admin_news_index_path, notice: "News deleted."
    end

    def publish
      @news_item.publish!
      redirect_to admin_news_path(@news_item), notice: "News published."
    end

    def approve
      @news_item.approve!
      redirect_to admin_news_path(@news_item), notice: "News approved."
    end

    def reject
      @news_item.reject!(params[:rejection_reason])
      redirect_to admin_news_path(@news_item), notice: "News rejected."
    end

    def submit_for_review
      @news_item.submit_for_review!
      redirect_to admin_news_path(@news_item), notice: "News submitted for review."
    end

    private

    def set_news_item
      @news_item = News.find(params[:id])
    end

    def set_form_collections
      @regions = Region.active.ordered
      @categories = Category.active.ordered
    end

    def authorize_edit
      raise Authorization::NotAuthorizedError unless current_user.can_edit_news?(@news_item)
    end

    def authorize_delete
      raise Authorization::NotAuthorizedError unless current_user.can_delete_news?
    end

    def news_params
      params.require(:news).permit(
        :title_en, :title_hi, :content_en, :content_hi,
        :region_id, :category_id, :cover_image,
        images: []
      )
    end
  end
end
