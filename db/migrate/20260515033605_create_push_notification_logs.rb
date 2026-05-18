class CreatePushNotificationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :push_notification_logs do |t|
      t.string :title, null: false
      t.string :url
      t.integer :total_subscribers, default: 0, null: false
      t.integer :sent_count, default: 0, null: false
      t.integer :failed_count, default: 0, null: false
      t.integer :removed_count, default: 0, null: false
      t.references :triggered_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :push_notification_logs, :created_at
  end
end
