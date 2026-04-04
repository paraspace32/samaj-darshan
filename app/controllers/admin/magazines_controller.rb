module Admin
  class MagazinesController < BaseController
    before_action :set_magazine, only: [ :show, :edit, :update, :destroy, :publish ]

    def index
      @magazines = Magazine.order(issue_number: :desc)
      @magazines = @magazines.where(status: params[:status]) if params[:status].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @magazines = @magazines.where("title_en ILIKE :q OR title_hi ILIKE :q", q: q)
      end
    end

    def show
      @articles = @magazine.magazine_articles.ordered.includes(:author)
    end

    def new
      @magazine = Magazine.new
    end

    def create
      @magazine = Magazine.new(magazine_params)
      if @magazine.save
        redirect_to admin_magazine_path(@magazine), notice: "Magazine created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @magazine.update(magazine_params)
        redirect_to admin_magazine_path(@magazine), notice: "Magazine updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @magazine.destroy
      redirect_to admin_magazines_path, notice: "Magazine deleted."
    end

    def publish
      @magazine.publish!
      redirect_to admin_magazine_path(@magazine), notice: "Magazine published."
    end

    private

    def set_magazine
      @magazine = Magazine.find(params[:id])
    end

    def magazine_params
      params.require(:magazine).permit(
        :title_en, :title_hi, :description_en, :description_hi,
        :issue_number, :volume, :cover_image
      )
    end
  end
end
