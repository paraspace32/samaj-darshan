module Api
  module V1
    module Admin
      class NewsController < BaseController
        before_action :set_news_item, only: [ :show, :update, :destroy, :publish, :approve, :reject, :submit_for_review ]
        before_action :require_editor_access, only: [ :publish, :approve, :reject ]

        def index
          news_items = News.includes(:region, :category, :author).order(created_at: :desc)
          news_items = news_items.where(status: params[:status]) if params[:status].present?
          news_items = news_items.where(region_id: params[:region_id]) if params[:region_id].present?
          news_items = news_items.where(category_id: params[:category_id]) if params[:category_id].present?

          result = paginate(news_items)
          render json: {
            news: result[:records].map { |n| admin_news_json(n) },
            meta: result[:meta]
          }
        end

        def show
          render json: { news: admin_news_json(@news_item, full: true) }
        end

        def create
          news_item = News.new(news_params)
          news_item.author = current_user
          news_item.save!
          render json: { news: admin_news_json(news_item, full: true) }, status: :created
        end

        def update
          @news_item.update!(news_params)
          render json: { news: admin_news_json(@news_item, full: true) }
        end

        def destroy
          @news_item.destroy!
          render json: { message: "News deleted" }
        end

        def publish
          @news_item.publish!
          render json: { news: admin_news_json(@news_item), message: "Published" }
        end

        def approve
          @news_item.approve!
          render json: { news: admin_news_json(@news_item), message: "Approved" }
        end

        def reject
          @news_item.reject!(params[:rejection_reason])
          render json: { news: admin_news_json(@news_item), message: "Rejected" }
        end

        def submit_for_review
          @news_item.submit_for_review!
          render json: { news: admin_news_json(@news_item), message: "Submitted for review" }
        end

        private

        def set_news_item
          @news_item = News.find(params[:id])
        end

        def news_params
          params.require(:news).permit(
            :title_en, :title_hi, :content_en, :content_hi,
            :region_id, :category_id, :cover_image,
            images: []
          )
        end

        def admin_news_json(news_item, full: false)
          data = {
            id: news_item.id,
            title_en: news_item.title_en,
            title_hi: news_item.title_hi,
            status: news_item.status,
            region_id: news_item.region_id,
            category_id: news_item.category_id,
            author: { id: news_item.author_id, name: news_item.author.name },
            published_at: news_item.published_at&.iso8601,
            rejection_reason: news_item.rejection_reason,
            created_at: news_item.created_at.iso8601,
            updated_at: news_item.updated_at.iso8601
          }

          if full
            data[:content_en] = news_item.content_en
            data[:content_hi] = news_item.content_hi
          end

          data
        end
      end
    end
  end
end
