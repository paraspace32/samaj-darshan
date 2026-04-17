class CreateRelatives < ActiveRecord::Migration[8.1]
  def change
    create_table :relatives do |t|
      t.references :biodata, null: false, foreign_key: true
      t.string :relative_type
      t.string :name

      t.timestamps
    end
  end
end
