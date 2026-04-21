class AddEngagementToJobPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :job_posts, :likes_count, :integer, default: 0, null: false
    add_column :job_posts, :comments_count, :integer, default: 0, null: false
  end
end
