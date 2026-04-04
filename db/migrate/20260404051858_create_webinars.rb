class CreateWebinars < ActiveRecord::Migration[8.1]
  def change
    create_table :webinars do |t|
      t.string :title_en, null: false
      t.string :title_hi, null: false
      t.text :description_en, null: false
      t.text :description_hi, null: false
      t.string :speaker_name, null: false
      t.string :speaker_bio
      t.integer :platform, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, default: 60, null: false
      t.string :meeting_url
      t.references :host, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :webinars, :status
    add_index :webinars, :starts_at
    add_index :webinars, [:status, :starts_at]
  end
end
