module Admin
  class BiodatasController < Admin::BaseController
    before_action :require_biodata_reviewer, only: [ :index, :show ]
    before_action :require_biodata_manager,  only: [ :new, :create, :publish, :reject, :search_users ]
    before_action :require_biodata_delete,   only: [ :destroy ]
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

    def search_users
      q = params[:q].to_s.strip
      users = if q.length >= 1
        User.active_users
            .where("name ILIKE :q OR phone ILIKE :q", q: "%#{q}%")
            .order(Arel.sql("LOWER(COALESCE(name, phone))"))
            .limit(15)
      else
        User.active_users
            .order(Arel.sql("LOWER(COALESCE(name, phone))"))
            .limit(15)
      end
      render json: users.map { |u| { id: u.id, label: "#{u.name.presence || "—"} · #{u.phone}" } }
    end

    def new
      @biodata = Biodata.new
      load_eligible_users
    end

    def create
      user_id = params.dig(:biodata, :user_id).presence
      user    = User.find_by(id: user_id)

      if user.nil?
        @biodata = Biodata.new(biodata_attrs)
        @biodata.errors.add(:user_id, "must be selected")
        load_eligible_users
        render :new, status: :unprocessable_entity and return
      end

      @biodata = user.biodatas.build(biodata_attrs)
      @biodata.status = :published
      @biodata.published_at = Time.current

      if @biodata.save
        redirect_to admin_biodata_path(@biodata),
                    notice: "Biodata created for #{user.name.presence || user.phone}."
      else
        load_eligible_users
        render :new, status: :unprocessable_entity
      end
    end

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

    def load_eligible_users
      @eligible_users = User.active_users
                            .order(Arel.sql("LOWER(COALESCE(name, phone))"))
    end

    def biodata_attrs
      params.require(:biodata).permit(
        :full_name, :full_name_hi, :gender, :date_of_birth,
        :caste, :mother_tongue,
        :city, :city_hi, :state, :country,
        :education, :occupation, :job_location, :annual_income,
        :height_cm, :complexion,
        :about_en, :about_hi,
        :father_name, :father_occupation, :mother_name, :mother_occupation, :siblings_count,
        :contact_phone, :contact_email,
        :partner_age_min, :partner_age_max, :partner_education, :partner_occupation, :partner_expectations,
        :photo
      )
    end
  end
end
