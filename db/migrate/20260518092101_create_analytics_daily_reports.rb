class CreateAnalyticsDailyReports < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_daily_reports do |t|
      t.date :date
      t.integer :visit_unique
      t.integer :visit_views
      t.integer :visit_new
      t.integer :visit_returning
      t.integer :visit_bots
      t.integer :visit_avg_duration
      t.integer :ga_users
      t.integer :ga_sessions
      t.integer :ga_pageviews
      t.integer :ga_new_users
      t.jsonb :top_pages
      t.jsonb :top_cities
      t.jsonb :devices
      t.float :user_delta_pct
      t.float :view_delta_pct

      t.timestamps
    end
    add_index :analytics_daily_reports, :date, unique: true
  end
end
