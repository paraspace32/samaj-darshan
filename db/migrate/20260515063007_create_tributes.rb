class CreateTributes < ActiveRecord::Migration[8.1]
  def change
    create_table :tributes do |t|
      t.string :name_en, null: false
      t.string :name_hi
      t.text :description_en, null: false
      t.text :description_hi
      t.integer :flowers_count, default: 0, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
