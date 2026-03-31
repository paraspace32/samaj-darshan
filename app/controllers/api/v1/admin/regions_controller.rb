module Api
  module V1
    module Admin
      class RegionsController < BaseController
        before_action :set_region, only: [ :show, :update, :destroy, :toggle_active ]

        def index
          regions = Region.order(:position, :name_en)
          render json: { regions: regions.map { |r| region_json(r) } }
        end

        def show
          render json: { region: region_json(@region) }
        end

        def create
          region = Region.create!(region_params)
          render json: { region: region_json(region) }, status: :created
        end

        def update
          @region.update!(region_params)
          render json: { region: region_json(@region) }
        end

        def destroy
          @region.destroy!
          render json: { message: "Region deleted" }
        end

        def toggle_active
          @region.update!(active: !@region.active)
          render json: { region: region_json(@region), message: @region.active? ? "Activated" : "Deactivated" }
        end

        private

        def set_region
          @region = Region.find(params[:id])
        end

        def region_params
          params.require(:region).permit(:name_en, :name_hi, :position, :active)
        end

        def region_json(region)
          {
            id: region.id,
            name_en: region.name_en,
            name_hi: region.name_hi,
            slug: region.slug,
            position: region.position,
            active: region.active,
            articles_count: region.articles.count
          }
        end
      end
    end
  end
end
