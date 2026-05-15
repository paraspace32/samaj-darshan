class PushNotificationLog < ApplicationRecord
  belongs_to :triggered_by, class_name: "User", optional: true

  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def delivery_rate
    return 0 if total_subscribers.zero?
    (sent_count.to_f / total_subscribers * 100).round(1)
  end
end
