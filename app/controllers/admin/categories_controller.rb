module Admin
  class CategoriesController < BaseController
    before_action :require_super_admin
    before_action :set_category, only: [ :edit, :update, :destroy, :toggle_active ]

    def index
      @categories = Category.order(:position, :name_en)
      @category = Category.new(color: "#6366f1")
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path, notice: "Category created."
      else
        @categories = Category.order(:position, :name_en)
        render :index, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.order(:position, :name_en)
      render :index
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category updated."
      else
        @categories = Category.order(:position, :name_en)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.destroy
        redirect_to admin_categories_path, notice: "Category deleted."
      else
        redirect_to admin_categories_path, alert: @category.errors.full_messages.to_sentence
      end
    end

    def toggle_active
      @category.update!(active: !@category.active)
      redirect_to admin_categories_path, notice: "Category #{@category.active? ? 'activated' : 'deactivated'}."
    end

    private

    def set_category
      @category = Category.find_by!(slug: params[:id])
    end

    def category_params
      params.require(:category).permit(:name_en, :name_hi, :color, :position, :active)
    end
  end
end
