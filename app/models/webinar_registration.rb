class WebinarRegistration < ApplicationRecord
  belongs_to :webinar

  validates :name, presence: true
  validates :phone, presence: true,
                    format: { with: /\A[6-9]\d{9}\z/, message: "must be a valid 10-digit mobile number" },
                    uniqueness: { scope: :webinar_id, message: "is already registered for this webinar" }
end
