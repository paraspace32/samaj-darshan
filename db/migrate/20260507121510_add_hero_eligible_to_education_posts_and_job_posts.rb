class AddHeroEligibleToEducationPostsAndJobPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :education_posts, :hero_eligible, :boolean, default: false, null: false
    add_column :job_posts, :hero_eligible, :boolean, default: false, null: false
  end
end
