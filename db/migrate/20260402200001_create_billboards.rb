class CreateBillboards < ActiveRecord::Migration[8.1]
  def change
    create_table :billboards do |t|
      t.string :title, null: false
      t.string :link_url
      t.integer :billboard_type, null: false, default: 0
      t.date :start_date
      t.date :end_date
      t.boolean :active, null: false, default: true
      t.integer :priority, null: false, default: 0
      t.integer :impressions_count, null: false, default: 0
      t.integer :clicks_count, null: false, default: 0
      t.timestamps
    end

    add_index :billboards, :billboard_type
    add_index :billboards, :active
    add_index :billboards, [:active, :billboard_type, :priority], name: "idx_billboards_active_type_priority"
  end
end
