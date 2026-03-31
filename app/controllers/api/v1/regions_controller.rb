module Api
  module V1
    class RegionsController < BaseController
      def index
        regions = Region.active.ordered
        render json: {
          regions: regions.map { |r| region_json(r) }
        }
      end

      def show
        region = Region.find_by!(slug: params[:id])
        render json: { region: region_json(region) }
      end

      private

      def region_json(region)
        {
          id: region.id,
          name_en: region.name_en,
          name_hi: region.name_hi,
          slug: region.slug,
          active: region.active,
          articles_count: region.articles.published.count
        }
      end
    end
  end
end
