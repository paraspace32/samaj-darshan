module Admin
  class KanyadaanApplicationsController < BaseController
    before_action :require_kanyadaan_access
    before_action :set_application, only: %i[show update]

    def index
      @applications = KanyadaanApplication.newest_first
      @applications = @applications.where(status: params[:status]) if params[:status].present?
    end

    def show
    end

    def update
      if @application.update(application_params)
        redirect_to admin_kanyadaan_application_path(@application), notice: "Application updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_application
      @application = KanyadaanApplication.find(params[:id])
    end

    def application_params
      params.require(:kanyadaan_application).permit(:status, :notes)
    end

    def require_kanyadaan_access
      redirect_to root_path, alert: "Not authorized" unless current_user.can_manage_kanyadaan?
    end
  end
end
