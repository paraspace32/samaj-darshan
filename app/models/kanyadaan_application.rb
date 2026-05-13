class KanyadaanApplication < ApplicationRecord
  enum :status, { pending: 0, reviewed: 1, approved: 2, rejected: 3 }

  validates :girl_name, presence: true
  validates :parent_name, presence: true
  validates :contact, presence: true,
                      format: { with: /\A[6-9]\d{9}\z/, message: "must be a valid 10-digit Indian mobile number" }
  validates :location, presence: true

  scope :newest_first, -> { order(created_at: :desc) }
end
