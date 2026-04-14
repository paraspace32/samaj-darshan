module Admin
  class BiodatasController < Admin::BaseController
    before_action :set_biodata, only: [ :show, :destroy, :publish, :reject ]

    def index
      @biodatas = Biodata.includes(:user).with_attached_photo
      @biodatas = @biodatas.where(status: params[:status]) if params[:status].present?
      @biodatas = @biodatas.where(gender: params[:gender]) if params[:gender].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @biodatas = @biodatas.where("full_name ILIKE :q OR city ILIKE :q", q: q)
      end
      @biodatas = @biodatas.order(created_at: :desc)
      @per_page = 25
      @page = [ params[:page].to_i, 1 ].max
      @total_count = @biodatas.count
      @biodatas = @biodatas.offset((@page - 1) * @per_page).limit(@per_page)
      @pending_count = Biodata.pending_review.count
    end

    def show; end

    def publish
      @biodata.publish!
      redirect_to admin_biodata_path(@biodata), notice: "Biodata published successfully."
    end

    def reject
      @biodata.reject!(params[:rejection_reason].to_s)
      redirect_to admin_biodatas_path, notice: "Biodata rejected."
    end

    def destroy
      @biodata.destroy
      redirect_to admin_biodatas_path, notice: "Biodata deleted."
    end

    private

    def set_biodata
      @biodata = Biodata.find(params[:id])
    end
  end
end
