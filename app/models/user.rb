class User < ApplicationRecord
  has_secure_password

  SECTIONS = %w[news magazines webinars education jobs billboards].freeze

  has_many :news, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :webinars, foreign_key: :host_id, dependent: :restrict_with_error
  has_many :magazine_articles, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :education_posts, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :job_posts, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_one :biodata, dependent: :destroy
  has_many :shortlists, dependent: :destroy
  has_many :shortlisted_biodatas, through: :shortlists, source: :biodata

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
  validate :allowed_sections_must_be_valid

  scope :by_role, ->(role) { where(role: role) }
  scope :active_users, -> { where(status: :active) }

  def has_section_access?(section)
    super_admin? || allowed_sections.include?(section.to_s)
  end

  def admin_panel_access?
    super_admin? || editor? || co_editor? || moderator?
  end

  def can_access_news_section?
    has_section_access?("news") || co_editor? || moderator?
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
    super_admin? || (editor? && has_section_access?("billboards"))
  end

  def can_manage_live_streams?
    super_admin? || (editor? && has_section_access?("news"))
  end

  def can_manage_webinars?
    super_admin? || (editor? && has_section_access?("webinars"))
  end

  def can_manage_magazines?
    super_admin? || (editor? && has_section_access?("magazines"))
  end

  def can_manage_education?
    super_admin? || (editor? && has_section_access?("education"))
  end

  def can_manage_jobs?
    super_admin? || (editor? && has_section_access?("jobs"))
  end

  def can_manage_biodatas?
    super_admin? || editor?
  end

  def can_review_biodatas?
    super_admin? || editor? || moderator?
  end

  def can_delete_biodatas?
    super_admin?
  end

  def can_create_news?
    super_admin? || (editor? && has_section_access?("news")) || co_editor?
  end

  def can_edit_any_news?
    super_admin? || (editor? && has_section_access?("news"))
  end

  def can_edit_news?(news_item)
    can_edit_any_news? || (co_editor? && news_item.author_id == id)
  end

  def can_publish?
    super_admin? || (editor? && has_section_access?("news"))
  end

  def can_review?
    super_admin? || (editor? && has_section_access?("news"))
  end

  def can_delete_news?
    super_admin?
  end

  def can_flag_news?
    super_admin? || (editor? && has_section_access?("news")) || moderator?
  end

  private

  def allowed_sections_must_be_valid
    return if allowed_sections.blank?

    invalid = allowed_sections - SECTIONS
    if invalid.any?
      errors.add(:allowed_sections, "contains invalid sections: #{invalid.join(', ')}")
    end
  end
end
