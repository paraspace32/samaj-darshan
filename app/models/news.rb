class News < ApplicationRecord
  include Bilingual
  bilingual_field :title, :content

  belongs_to :region
  belongs_to :category
  belongs_to :author, class_name: "User"

  has_many :comments, as: :commentable, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  has_one_attached :cover_image do |attachable|
    attachable.variant :hero,     resize_to_fill: [1600, 800], format: :webp, saver: { quality: 92 }
    attachable.variant :card,     resize_to_fill: [800, 450],  format: :webp, saver: { quality: 90 }
    attachable.variant :thumb,    resize_to_fill: [200, 140],  format: :webp, saver: { quality: 85 }
    attachable.variant :carousel, resize_to_limit: [1600, 1000], format: :webp, saver: { quality: 92 }
  end

  has_many_attached :images do |attachable|
    attachable.variant :carousel, resize_to_limit: [1600, 1000], format: :webp, saver: { quality: 92 }
    attachable.variant :thumb,    resize_to_fill: [300, 300],   format: :webp, saver: { quality: 85 }
  end

  enum :status, { draft: 0, pending_review: 1, approved: 2, published: 3, rejected: 4 }

  MAX_IMAGES = 10

  validate :title_in_at_least_one_language
  validate :content_in_at_least_one_language
  validate :images_count_within_limit

  scope :recent, -> { order(published_at: :desc, created_at: :desc) }
  scope :by_region, ->(region) { where(region: region) }
  scope :by_category, ->(category) { where(category: category) }
  scope :feed, -> { published.recent.includes(:region, :category, :author) }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def approve!
    update!(status: :approved, rejection_reason: nil)
  end

  def reject!(reason)
    update!(status: :rejected, rejection_reason: reason)
  end

  def submit_for_review!
    update!(status: :pending_review)
  end

  private

  def title_in_at_least_one_language
    if title_en.blank? && title_hi.blank?
      errors.add(:base, "Title must be provided in at least one language")
    end
  end

  def content_in_at_least_one_language
    if content_en.blank? && content_hi.blank?
      errors.add(:base, "Content must be provided in at least one language")
    end
  end

  def images_count_within_limit
    if images.count > MAX_IMAGES
      errors.add(:images, "cannot exceed #{MAX_IMAGES} (currently #{images.count})")
    end
  end
end
