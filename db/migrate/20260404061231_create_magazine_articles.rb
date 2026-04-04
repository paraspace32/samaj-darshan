class CreateMagazineArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :magazine_articles do |t|
      t.references :magazine, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title_en, null: false
      t.string :title_hi, null: false
      t.text :content_en, null: false
      t.text :content_hi, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :magazine_articles, [:magazine_id, :position]
  end
end
