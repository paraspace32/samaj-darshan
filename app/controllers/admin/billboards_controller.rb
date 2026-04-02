module Admin
  class BillboardsController < BaseController
    before_action :require_billboard_access
    before_action :set_billboard, only: [:edit, :update, :destroy, :toggle_active]

    def index
      @billboards = Billboard.order(created_at: :desc).with_attached_image
    end

    def new
      @billboard = Billboard.new(active: true, billboard_type: :top_banner)
    end

    def create
      @billboard = Billboard.new(billboard_params)
      if @billboard.save
        redirect_to admin_billboards_path, notice: "Billboard created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @billboard.update(billboard_params)
        redirect_to admin_billboards_path, notice: "Billboard updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @billboard.destroy
      redirect_to admin_billboards_path, notice: "Billboard deleted."
    end

    def toggle_active
      @billboard.update!(active: !@billboard.active?)
      redirect_to admin_billboards_path, notice: "Billboard #{@billboard.active? ? 'activated' : 'deactivated'}."
    end

    private

    def set_billboard
      @billboard = Billboard.find(params[:id])
    end

    def billboard_params
      params.require(:billboard).permit(:title, :link_url, :billboard_type, :start_date, :end_date, :active, :priority, :image)
    end
  end
end
