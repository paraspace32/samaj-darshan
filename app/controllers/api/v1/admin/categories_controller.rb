module Api
  module V1
    module Admin
      class CategoriesController < BaseController
        before_action :set_category, only: [ :show, :update, :destroy, :toggle_active ]

        def index
          categories = Category.order(:position, :name_en)
          render json: { categories: categories.map { |c| category_json(c) } }
        end

        def show
          render json: { category: category_json(@category) }
        end

        def create
          category = Category.create!(category_params)
          render json: { category: category_json(category) }, status: :created
        end

        def update
          @category.update!(category_params)
          render json: { category: category_json(@category) }
        end

        def destroy
          @category.destroy!
          render json: { message: "Category deleted" }
        end

        def toggle_active
          @category.update!(active: !@category.active)
          render json: { category: category_json(@category), message: @category.active? ? "Activated" : "Deactivated" }
        end

        private

        def set_category
          @category = Category.find(params[:id])
        end

        def category_params
          params.require(:category).permit(:name_en, :name_hi, :color, :position, :active)
        end

        def category_json(category)
          {
            id: category.id,
            name_en: category.name_en,
            name_hi: category.name_hi,
            slug: category.slug,
            color: category.color,
            position: category.position,
            active: category.active,
            articles_count: category.articles.count
          }
        end
      end
    end
  end
end
