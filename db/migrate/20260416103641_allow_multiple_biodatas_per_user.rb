class AllowMultipleBiodatasPerUser < ActiveRecord::Migration[8.1]
  def up
    if index_exists?(:biodatas, :user_id, unique: true)
      remove_index :biodatas, :user_id
      add_index :biodatas, :user_id
    end
  end

  def down
    if index_exists?(:biodatas, :user_id) && !index_exists?(:biodatas, :user_id, unique: true)
      remove_index :biodatas, :user_id
      add_index :biodatas, :user_id, unique: true
    end
  end
end
