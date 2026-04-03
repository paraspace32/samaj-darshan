class MakeCommentsAndLikesPolymorphic < ActiveRecord::Migration[8.1]
  def up
    # --- Comments ---
    add_column :comments, :commentable_type, :string
    add_column :comments, :commentable_id, :bigint

    # Migrate existing data: article_id -> commentable
    execute <<-SQL
      UPDATE comments SET commentable_type = 'Article', commentable_id = article_id;
    SQL

    change_column_null :comments, :commentable_type, false
    change_column_null :comments, :commentable_id, false

    add_index :comments, [ :commentable_type, :commentable_id ]
    remove_foreign_key :comments, :articles
    remove_column :comments, :article_id

    # --- Likes ---
    add_column :likes, :likeable_type, :string
    add_column :likes, :likeable_id, :bigint

    # Migrate existing data: article_id -> likeable
    execute <<-SQL
      UPDATE likes SET likeable_type = 'Article', likeable_id = article_id;
    SQL

    change_column_null :likes, :likeable_type, false
    change_column_null :likes, :likeable_id, false

    remove_index :likes, [ :article_id, :user_id ]
    remove_foreign_key :likes, :articles
    remove_column :likes, :article_id

    add_index :likes, [ :likeable_type, :likeable_id ]
    add_index :likes, [ :likeable_type, :likeable_id, :user_id ], unique: true, name: "index_likes_uniqueness"
  end

  def down
    # --- Comments ---
    add_reference :comments, :article, foreign_key: true

    execute <<-SQL
      UPDATE comments SET article_id = commentable_id WHERE commentable_type = 'Article';
    SQL

    remove_index :comments, [ :commentable_type, :commentable_id ]
    remove_column :comments, :commentable_type
    remove_column :comments, :commentable_id

    # --- Likes ---
    add_reference :likes, :article, foreign_key: true

    execute <<-SQL
      UPDATE likes SET article_id = likeable_id WHERE likeable_type = 'Article';
    SQL

    remove_index :likes, name: "index_likes_uniqueness"
    remove_index :likes, [ :likeable_type, :likeable_id ]
    remove_column :likes, :likeable_type
    remove_column :likes, :likeable_id

    add_index :likes, [ :article_id, :user_id ], unique: true
  end
end
