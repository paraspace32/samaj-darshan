class RenameArticlesToNews < ActiveRecord::Migration[8.1]
  def change
    rename_table :articles, :news

    remove_column :news, :article_type, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        execute "UPDATE comments SET commentable_type = 'News' WHERE commentable_type = 'Article'"
        execute "UPDATE likes SET likeable_type = 'News' WHERE likeable_type = 'Article'"
        execute "UPDATE active_storage_attachments SET record_type = 'News' WHERE record_type = 'Article'"
      end
      dir.down do
        execute "UPDATE comments SET commentable_type = 'Article' WHERE commentable_type = 'News'"
        execute "UPDATE likes SET likeable_type = 'Article' WHERE likeable_type = 'News'"
        execute "UPDATE active_storage_attachments SET record_type = 'Article' WHERE record_type = 'News'"
      end
    end
  end
end
