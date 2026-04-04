module Api
  module V1
    class NewsController < BaseController
      def index
        news_items = News.feed
        news_items = news_items.where(region_id: params[:region_id]) if params[:region_id].present?
        news_items = news_items.where(category_id: params[:category_id]) if params[:category_id].present?

        result = paginate(news_items)
        render json: {
          news: result[:records].map { |n| news_json(n) },
          meta: result[:meta]
        }
      end

      def show
        news_item = News.published.find(params[:id])
        render json: { news: news_json(news_item, full: true) }
      end

      private

      def news_json(news_item, full: false)
        data = {
          id: news_item.id,
          title_en: news_item.title_en,
          title_hi: news_item.title_hi,
          region: { id: news_item.region_id, name_en: news_item.region.name_en, name_hi: news_item.region.name_hi, slug: news_item.region.slug },
          category: { id: news_item.category_id, name_en: news_item.category.name_en, name_hi: news_item.category.name_hi, slug: news_item.category.slug, color: news_item.category.color },
          author: { id: news_item.author_id, name: news_item.author.name },
          published_at: news_item.published_at&.iso8601,
          cover_image_url: news_item.cover_image.attached? ? url_for(news_item.cover_image) : nil
        }

        if full
          data[:content_en] = news_item.content_en
          data[:content_hi] = news_item.content_hi
          data[:image_urls] = news_item.images.map { |img| url_for(img) } if news_item.images.attached?
        else
          data[:excerpt_en] = news_item.content_en.to_s.truncate(200)
          data[:excerpt_hi] = news_item.content_hi.to_s.truncate(200)
        end

        data
      end
    end
  end
end
