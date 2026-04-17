class Biodata < ApplicationRecord
  belongs_to :user
  has_many :shortlists, dependent: :destroy

  has_one_attached :photo do |attachable|
    attachable.variant :profile, resize_to_fill: [ 400, 500 ], format: :webp, saver: { quality: 85 }
    attachable.variant :card,    resize_to_fill: [ 240, 300 ], format: :webp, saver: { quality: 80 }
    attachable.variant :thumb,   resize_to_fill: [ 80, 80 ],   format: :webp, saver: { quality: 75 }
  end

  enum :gender, { male: 0, female: 1 }
  enum :status, { draft: 0, pending_review: 1, published: 2, rejected: 3 }

  validates :full_name,     presence: true
  validates :gender,        presence: true
  validates :date_of_birth, presence: true
  validate :age_must_be_reasonable

  scope :visible,       -> { published.order(published_at: :desc) }
  scope :for_gender,    ->(g)        { where(gender: g) if g.present? }
  scope :for_city,      ->(c)        { where("city ILIKE ?", "%#{c}%") if c.present? }
  scope :for_state,       ->(s) { where("state ILIKE ?", "%#{s}%") if s.present? }
  scope :for_education,   ->(e) { where("education ILIKE ?", "%#{e}%") if e.present? }
  scope :for_occupation,  ->(o) { where("occupation ILIKE ?", "%#{o}%") if o.present? }
  scope :for_age_range, ->(min, max) {
    return all unless min.present? || max.present?
    max_dob = min.present? ? Date.today - min.to_i.years : nil
    min_dob = max.present? ? Date.today - max.to_i.years : nil
    scope = all
    scope = scope.where("date_of_birth <= ?", max_dob) if max_dob
    scope = scope.where("date_of_birth >= ?", min_dob) if min_dob
    scope
  }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def reject!(reason)
    update!(status: :rejected, rejection_reason: reason)
  end

  def submit_for_review!
    update!(status: :pending_review)
  end

  def age
    return nil unless date_of_birth
    today = Date.today
    years = today.year - date_of_birth.year
    years -= 1 if today < date_of_birth + years.years
    years
  end

  def display_name
    I18n.locale == :hi && full_name_hi.present? ? full_name_hi : full_name.presence || "Unknown"
  end

  def avatar_initial
    (full_name.presence || display_name.presence || "?")[0].upcase
  end

  def display_about
    I18n.locale == :hi && about_hi.present? ? about_hi : about_en
  end

  def height_display
    return nil unless height_cm
    total_inches = (height_cm / 2.54).round
    feet = total_inches / 12
    inches = total_inches % 12
    "#{feet}'#{inches}\" (#{height_cm} cm)"
  end

  private

  def age_must_be_reasonable
    return unless date_of_birth
    computed = Date.today.year - date_of_birth.year
    errors.add(:date_of_birth, "must indicate age between 18 and 60") unless computed.between?(18, 60)
  end
end
