class CreateRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :regions do |t|
      t.string :name_en, null: false
      t.string :name_hi, null: false
      t.string :slug, null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :regions, :slug, unique: true
    add_index :regions, :position
    add_index :regions, :active
  end
end
