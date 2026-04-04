module Admin
  class WebinarsController < BaseController
    before_action :require_webinar_access
    before_action :set_webinar, only: [:show, :edit, :update, :destroy, :publish, :cancel]

    def index
      @webinars = Webinar.includes(:host).order(starts_at: :desc)
      @webinars = @webinars.where(status: params[:status]) if params[:status].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @webinars = @webinars.where("title_en ILIKE :q OR title_hi ILIKE :q OR speaker_name ILIKE :q", q: q)
      end
      @per_page = 20
      @page = [params[:page].to_i, 1].max
      @total_count = @webinars.count
      @webinars = @webinars.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show
    end

    def new
      @webinar = Webinar.new(status: :draft, platform: :zoom, duration_minutes: 60, starts_at: 1.day.from_now.beginning_of_hour)
    end

    def create
      @webinar = Webinar.new(webinar_params)
      @webinar.host = current_user

      if @webinar.save
        redirect_to admin_webinar_path(@webinar), notice: "Webinar created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @webinar.update(webinar_params)
        redirect_to admin_webinar_path(@webinar), notice: "Webinar updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @webinar.destroy
      redirect_to admin_webinars_path, notice: "Webinar deleted."
    end

    def publish
      @webinar.update!(status: :published)
      redirect_to admin_webinar_path(@webinar), notice: "Webinar published."
    end

    def cancel
      @webinar.update!(status: :cancelled)
      redirect_to admin_webinar_path(@webinar), notice: "Webinar cancelled."
    end

    private

    def set_webinar
      @webinar = Webinar.find(params[:id])
    end

    def require_webinar_access
      raise Authorization::NotAuthorizedError unless current_user.can_manage_webinars?
    end

    def webinar_params
      params.require(:webinar).permit(
        :title_en, :title_hi, :description_en, :description_hi,
        :speaker_name, :speaker_bio, :platform, :starts_at,
        :duration_minutes, :meeting_url, :cover_image
      )
    end
  end
end
