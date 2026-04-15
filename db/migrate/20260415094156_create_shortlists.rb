class CreateShortlists < ActiveRecord::Migration[8.1]
  def change
    create_table :shortlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :biodata, null: false, foreign_key: true

      t.timestamps
    end
    add_index :shortlists, [ :user_id, :biodata_id ], unique: true
  end
end
