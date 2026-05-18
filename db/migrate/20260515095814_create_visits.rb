class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.string   :visitor_token, null: false
      t.string   :ip_address
      t.string   :user_agent, limit: 512
      t.string   :path, null: false
      t.string   :referrer
      t.string   :city
      t.string   :country
      t.references :user, null: true, foreign_key: true
      t.boolean  :bot, default: false, null: false
      t.datetime :visited_at, null: false

      t.index [ :visitor_token, :visited_at ]
      t.index :visited_at
      t.index :path
      t.index :city
      t.index [ :visited_at, :bot ]
    end
  end
end
