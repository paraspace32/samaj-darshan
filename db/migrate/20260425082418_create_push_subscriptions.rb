class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: true, foreign_key: true, index: true
      t.string :token, null: false
      t.string :platform, null: false, default: "web"
      t.string :browser
      t.timestamps
    end

    add_index :push_subscriptions, :token, unique: true
  end
end
