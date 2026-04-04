module Admin
  class DashboardController < BaseController
    def show
      @stats = {
        articles_count: Article.count,
        news_count: Article.news_only.count,
        magazine_count: Article.magazine_only.count,
        published_count: Article.published.count,
        pending_count: Article.pending_review.count,
        draft_count: Article.draft.count,
        regions_count: Region.count,
        categories_count: Category.count,
        users_count: User.count,
        billboards_count: Billboard.count,
        webinars_count: Webinar.count,
        upcoming_webinars_count: Webinar.upcoming.count
      }

      @recent_articles = Article.includes(:region, :category, :author)
                                .order(created_at: :desc)
                                .limit(5)
    end
  end
end
