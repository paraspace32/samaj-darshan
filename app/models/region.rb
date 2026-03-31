class Region < ApplicationRecord
  include Bilingual
  bilingual_field :name

  has_many :articles, dependent: :restrict_with_error

  validates :name_en, presence: true, uniqueness: true
  validates :name_hi, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name_en.present? }

  scope :ordered, -> { order(:position, :name_en) }
  scope :active, -> { where(active: true) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name_en.to_s.encode("UTF-8").parameterize
  end
end
