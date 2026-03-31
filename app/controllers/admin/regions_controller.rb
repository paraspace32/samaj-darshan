module Admin
  class RegionsController < BaseController
    before_action :set_region, only: [ :edit, :update, :destroy, :toggle_active ]

    def index
      @regions = Region.order(:position, :name_en)
      @region = Region.new
    end

    def create
      @region = Region.new(region_params)
      if @region.save
        redirect_to admin_regions_path, notice: "Region created."
      else
        @regions = Region.order(:position, :name_en)
        render :index, status: :unprocessable_entity
      end
    end

    def edit
      @regions = Region.order(:position, :name_en)
      render :index
    end

    def update
      if @region.update(region_params)
        redirect_to admin_regions_path, notice: "Region updated."
      else
        @regions = Region.order(:position, :name_en)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      if @region.destroy
        redirect_to admin_regions_path, notice: "Region deleted."
      else
        redirect_to admin_regions_path, alert: @region.errors.full_messages.to_sentence
      end
    end

    def toggle_active
      @region.update!(active: !@region.active)
      redirect_to admin_regions_path, notice: "Region #{@region.active? ? 'activated' : 'deactivated'}."
    end

    private

    def set_region
      @region = Region.find(params[:id])
    end

    def region_params
      params.require(:region).permit(:name_en, :name_hi, :position, :active)
    end
  end
end
