module Api
  module V1
    class CategoriesController < BaseController
      def index
        categories = Category.active.ordered
        render json: {
          categories: categories.map { |c| category_json(c) }
        }
      end

      def show
        category = Category.find_by!(slug: params[:id])
        render json: { category: category_json(category) }
      end

      private

      def category_json(category)
        {
          id: category.id,
          name_en: category.name_en,
          name_hi: category.name_hi,
          slug: category.slug,
          color: category.color,
          active: category.active,
          articles_count: category.articles.published.count
        }
      end
    end
  end
end
