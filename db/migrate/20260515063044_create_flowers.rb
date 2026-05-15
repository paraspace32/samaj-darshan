class CreateFlowers < ActiveRecord::Migration[8.1]
  def change
    create_table :flowers do |t|
      t.references :tribute, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :flowers, [ :tribute_id, :user_id ], unique: true
  end
end
