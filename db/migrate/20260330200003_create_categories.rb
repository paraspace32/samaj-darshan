class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name_en, null: false
      t.string :name_hi, null: false
      t.string :slug, null: false
      t.string :color, default: "#6366f1", null: false
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :position
    add_index :categories, :active
  end
end
