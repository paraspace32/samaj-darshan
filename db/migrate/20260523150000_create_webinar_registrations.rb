class CreateWebinarRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :webinar_registrations do |t|
      t.references :webinar, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone, null: false
      t.timestamps
    end

    add_index :webinar_registrations, [ :webinar_id, :phone ], unique: true
  end
end
