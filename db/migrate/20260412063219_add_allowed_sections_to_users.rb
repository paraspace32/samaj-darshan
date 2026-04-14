class AddAllowedSectionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :allowed_sections, :jsonb, default: [], null: false
  end
end
