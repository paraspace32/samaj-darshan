class AddLikesCountAndCommentsCountToEducationPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :education_posts, :likes_count, :integer, default: 0, null: false
    add_column :education_posts, :comments_count, :integer, default: 0, null: false
  end
end
