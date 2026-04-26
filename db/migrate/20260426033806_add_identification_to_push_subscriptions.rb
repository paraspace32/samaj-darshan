class AddIdentificationToPushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    # OS the subscriber is on: android | ios | windows | macos | linux | unknown
    add_column :push_subscriptions, :os, :string, null: false, default: "unknown"

    # How the app was opened when the token was registered:
    #   "browser"    → normal browser tab (address bar visible)
    #   "standalone" → installed PWA launched from home screen / app drawer
    add_column :push_subscriptions, :display_mode, :string, null: false, default: "browser"

    # Index so we can efficiently query by segment
    add_index :push_subscriptions, [ :platform, :os ]
    add_index :push_subscriptions, :display_mode
  end
end
