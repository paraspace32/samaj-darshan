class CreateKanyadaanApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :kanyadaan_applications do |t|
      t.string :girl_name, null: false
      t.string :parent_name, null: false
      t.string :contact, null: false
      t.string :location, null: false
      t.integer :status, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :kanyadaan_applications, :status
    add_index :kanyadaan_applications, :created_at
  end
end
