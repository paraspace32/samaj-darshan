class CreateEducationPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :education_posts do |t|
      t.string :title_en, null: false
      t.string :title_hi, null: false
      t.text :content_en, null: false
      t.text :content_hi, null: false
      t.integer :category, default: 0, null: false
      t.string :organization_name
      t.date :exam_date
      t.date :registration_deadline
      t.string :official_url
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :education_posts, :status
    add_index :education_posts, :category
    add_index :education_posts, :published_at
    add_index :education_posts, [ :status, :published_at ]
    add_index :education_posts, [ :status, :category ]
  end
end
