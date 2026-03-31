class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title_en, null: false
      t.string :title_hi, null: false
      t.text :content_en, null: false
      t.text :content_hi, null: false
      t.references :region, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false
      t.integer :article_type, default: 0, null: false
      t.datetime :published_at
      t.string :rejection_reason

      t.timestamps
    end

    add_index :articles, :status
    add_index :articles, :article_type
    add_index :articles, :published_at
    add_index :articles, [ :status, :published_at ]
  end
end
