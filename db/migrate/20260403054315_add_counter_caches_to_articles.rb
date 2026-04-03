class AddCounterCachesToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :likes_count, :integer, default: 0, null: false
    add_column :articles, :comments_count, :integer, default: 0, null: false
  end
end
