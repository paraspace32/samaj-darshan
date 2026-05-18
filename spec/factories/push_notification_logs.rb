FactoryBot.define do
  factory :push_notification_log do
    title { "Test Notification" }
    sent_count { 10 }
    failed_count { 2 }
    removed_count { 1 }
    total_subscribers { 13 }
  end
end
