class CreateBiodatas < ActiveRecord::Migration[8.1]
  def change
    create_table :biodatas do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string  :full_name, null: false
      t.string  :full_name_hi
      t.integer :gender, null: false, default: 0
      t.date    :date_of_birth, null: false
      t.string  :religion
      t.string  :caste
      t.string  :mother_tongue
      t.string  :city, null: false
      t.string  :state
      t.string  :country, default: "India"
      t.string  :education, null: false
      t.string  :occupation
      t.string  :annual_income
      t.integer :height_cm
      t.string  :complexion
      t.text    :about_en
      t.text    :about_hi
      t.string  :father_occupation
      t.string  :mother_occupation
      t.integer :siblings_count, default: 0
      t.string  :contact_phone
      t.string  :contact_email
      t.integer :status, null: false, default: 0
      t.text    :rejection_reason
      t.datetime :published_at
      t.timestamps
    end

    add_index :biodatas, :status
    add_index :biodatas, :gender
    add_index :biodatas, :date_of_birth
    add_index :biodatas, :city
    add_index :biodatas, [ :gender, :status ]
    add_index :biodatas, [ :status, :published_at ]
  end
end
