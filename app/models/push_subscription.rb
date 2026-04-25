class PushSubscription < ApplicationRecord
  belongs_to :user, optional: true

  validates :token, presence: true, uniqueness: true
  validates :platform, inclusion: { in: %w[web android ios] }

  scope :web, -> { where(platform: "web") }

  # Remove an invalid/expired token silently
  def self.remove_token(token)
    find_by(token: token)&.destroy
  end
end
