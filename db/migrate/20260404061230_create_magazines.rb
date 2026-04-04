class CreateMagazines < ActiveRecord::Migration[8.1]
  def change
    create_table :magazines do |t|
      t.string :title_en, null: false
      t.string :title_hi, null: false
      t.text :description_en
      t.text :description_hi
      t.integer :issue_number, null: false
      t.string :volume
      t.integer :status, default: 0, null: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :magazines, :issue_number, unique: true
    add_index :magazines, :status
    add_index :magazines, [ :status, :published_at ]
  end
end
