class User < ApplicationRecord
  has_secure_password

  has_many :articles, foreign_key: :author_id, dependent: :restrict_with_error

  enum :role, { super_admin: 0, admin: 1, editor: 2, contributor: 3 }
  enum :status, { active: 0, blocked: 1 }, prefix: :account

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true,
                    format: { with: /\A[6-9]\d{9}\z/, message: "must be a valid 10-digit Indian mobile number" }
  validates :email, uniqueness: true, allow_blank: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }
  validates :role, presence: true
  validates :status, presence: true

  scope :by_role, ->(role) { where(role: role) }
  scope :active_users, -> { where(status: :active) }

  def admin_or_above?
    super_admin? || admin?
  end

  def can_publish?
    super_admin? || admin? || editor?
  end

  def can_review?
    super_admin? || admin? || editor?
  end
end
