module Admin
  class DashboardController < BaseController
    def show
      @stats = {
        news_count: News.count,
        published_count: News.published.count,
        pending_count: News.pending_review.count,
        draft_count: News.draft.count,
        magazines_count: Magazine.count,
        published_magazines_count: Magazine.published.count,
        regions_count: Region.count,
        categories_count: Category.count,
        users_count: User.count,
        billboards_count: Billboard.count,
        webinars_count: Webinar.count,
        upcoming_webinars_count: Webinar.upcoming.count,
        biodatas_total: Biodata.count,
        biodatas_pending: Biodata.pending_review.count,
        biodatas_published: Biodata.published.count
      }

      @recent_news = News.includes(:region, :category, :author)
                         .order(created_at: :desc)
                         .limit(5)
    end
  end
end
