class CreateJobPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :job_posts do |t|
      t.string :title_en, null: false
      t.string :title_hi, null: false
      t.text :description_en, null: false
      t.text :description_hi, null: false
      t.integer :category, default: 0, null: false
      t.string :company_name, null: false
      t.string :location
      t.date :deadline
      t.string :application_url
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :job_posts, :status
    add_index :job_posts, :category
    add_index :job_posts, :published_at
    add_index :job_posts, [ :status, :published_at ]
    add_index :job_posts, [ :status, :category ]
  end
end
