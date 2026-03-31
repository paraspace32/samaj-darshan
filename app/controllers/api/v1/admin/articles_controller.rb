module Api
  module V1
    module Admin
      class ArticlesController < BaseController
        before_action :set_article, only: [ :show, :update, :destroy, :publish, :approve, :reject, :submit_for_review ]
        before_action :require_editor_access, only: [ :publish, :approve, :reject ]

        def index
          articles = Article.includes(:region, :category, :author).order(created_at: :desc)
          articles = articles.where(status: params[:status]) if params[:status].present?
          articles = articles.where(region_id: params[:region_id]) if params[:region_id].present?
          articles = articles.where(category_id: params[:category_id]) if params[:category_id].present?

          result = paginate(articles)
          render json: {
            articles: result[:records].map { |a| admin_article_json(a) },
            meta: result[:meta]
          }
        end

        def show
          render json: { article: admin_article_json(@article, full: true) }
        end

        def create
          article = Article.new(article_params)
          article.author = current_user
          article.save!
          render json: { article: admin_article_json(article, full: true) }, status: :created
        end

        def update
          @article.update!(article_params)
          render json: { article: admin_article_json(@article, full: true) }
        end

        def destroy
          @article.destroy!
          render json: { message: "Article deleted" }
        end

        def publish
          @article.publish!
          render json: { article: admin_article_json(@article), message: "Published" }
        end

        def approve
          @article.approve!
          render json: { article: admin_article_json(@article), message: "Approved" }
        end

        def reject
          @article.reject!(params[:rejection_reason])
          render json: { article: admin_article_json(@article), message: "Rejected" }
        end

        def submit_for_review
          @article.submit_for_review!
          render json: { article: admin_article_json(@article), message: "Submitted for review" }
        end

        private

        def set_article
          @article = Article.find(params[:id])
        end

        def article_params
          params.require(:article).permit(
            :title_en, :title_hi, :content_en, :content_hi,
            :region_id, :category_id, :article_type, :cover_image,
            images: []
          )
        end

        def admin_article_json(article, full: false)
          data = {
            id: article.id,
            title_en: article.title_en,
            title_hi: article.title_hi,
            status: article.status,
            article_type: article.article_type,
            region_id: article.region_id,
            category_id: article.category_id,
            author: { id: article.author_id, name: article.author.name },
            published_at: article.published_at&.iso8601,
            rejection_reason: article.rejection_reason,
            created_at: article.created_at.iso8601,
            updated_at: article.updated_at.iso8601
          }

          if full
            data[:content_en] = article.content_en
            data[:content_hi] = article.content_hi
          end

          data
        end
      end
    end
  end
end
