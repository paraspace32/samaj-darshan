class User < ApplicationRecord
  has_secure_password

  has_many :articles, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  enum :role, { super_admin: 0, editor: 1, co_editor: 2, moderator: 3, user: 4 }
  enum :status, { active: 0, blocked: 1 }, prefix: :account

  before_validation { self.email = nil if email.blank? }

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true,
                    format: { with: /\A[6-9]\d{9}\z/, message: "must be a valid 10-digit Indian mobile number" }
  validates :email, uniqueness: true, allow_blank: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email" }
  validates :role, presence: true
  validates :status, presence: true

  scope :by_role, ->(role) { where(role: role) }
  scope :active_users, -> { where(status: :active) }

  def admin_panel_access?
    super_admin? || editor? || co_editor? || moderator?
  end

  def can_manage_users?
    super_admin?
  end

  def can_manage_regions?
    super_admin?
  end

  def can_manage_categories?
    super_admin?
  end

  def can_manage_billboards?
    super_admin? || editor?
  end

  def can_manage_live_streams?
    super_admin? || editor?
  end

  def can_create_articles?
    super_admin? || editor? || co_editor?
  end

  def can_edit_any_article?
    super_admin? || editor?
  end

  def can_edit_article?(article)
    can_edit_any_article? || (co_editor? && article.author_id == id)
  end

  def can_publish?
    super_admin? || editor?
  end

  def can_review?
    super_admin? || editor?
  end

  def can_delete_articles?
    super_admin?
  end

  def can_flag_articles?
    super_admin? || editor? || moderator?
  end
end
