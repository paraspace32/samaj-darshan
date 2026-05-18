class AnalyticsDailyReport < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  scope :recent, -> { order(date: :desc) }

  def user_delta
    return nil unless ga_users && visit_unique
    visit_unique - ga_users
  end

  def view_delta
    return nil unless ga_pageviews && visit_views
    visit_views - ga_pageviews
  end

  def ga_available?
    ga_users.present?
  end

  def alert?
    user_delta_pct.present? && user_delta_pct.abs > 30
  end
end
