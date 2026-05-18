module Admin
  class TributesController < BaseController
    before_action :require_tribute_access
    before_action :set_tribute, only: %i[edit update destroy]

    def index
      @tributes = Tribute.recent.with_attached_image
    end

    def new
      @tribute = Tribute.new
    end

    def create
      @tribute = Tribute.new(tribute_params)
      @tribute.created_by = current_user

      if @tribute.save
        redirect_to admin_tributes_path, notice: "Tribute created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @tribute.update(tribute_params)
        redirect_to admin_tributes_path, notice: "Tribute updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tribute.destroy
      redirect_to admin_tributes_path, notice: "Tribute deleted."
    end

    private

    def set_tribute
      @tribute = Tribute.find(params[:id])
    end

    def require_tribute_access
      redirect_to root_path, alert: "Not authorized" unless current_user.can_manage_tributes?
    end

    def tribute_params
      params.require(:tribute).permit(:name_en, :name_hi, :description_en, :description_hi, :image)
    end
  end
end
