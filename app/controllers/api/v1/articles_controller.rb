module Api
  module V1
    class ArticlesController < BaseController
      def index
        articles = Article.feed
        articles = articles.where(region_id: params[:region_id]) if params[:region_id].present?
        articles = articles.where(category_id: params[:category_id]) if params[:category_id].present?

        result = paginate(articles)
        render json: {
          articles: result[:records].map { |a| article_json(a) },
          meta: result[:meta]
        }
      end

      def show
        article = Article.published.find(params[:id])
        render json: { article: article_json(article, full: true) }
      end

      private

      def article_json(article, full: false)
        data = {
          id: article.id,
          title_en: article.title_en,
          title_hi: article.title_hi,
          region: { id: article.region_id, name_en: article.region.name_en, name_hi: article.region.name_hi, slug: article.region.slug },
          category: { id: article.category_id, name_en: article.category.name_en, name_hi: article.category.name_hi, slug: article.category.slug, color: article.category.color },
          author: { id: article.author_id, name: article.author.name },
          article_type: article.article_type,
          published_at: article.published_at&.iso8601,
          cover_image_url: article.cover_image.attached? ? url_for(article.cover_image) : nil
        }

        if full
          data[:content_en] = article.content_en
          data[:content_hi] = article.content_hi
          data[:image_urls] = article.images.map { |img| url_for(img) } if article.images.attached?
        else
          data[:excerpt_en] = article.content_en.to_s.truncate(200)
          data[:excerpt_hi] = article.content_hi.to_s.truncate(200)
        end

        data
      end
    end
  end
end
