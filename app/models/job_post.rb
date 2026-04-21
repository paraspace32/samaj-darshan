class JobPost < ApplicationRecord
  include Bilingual
  bilingual_field :title, :description

  belongs_to :author, class_name: "User"

  has_many :comments, as: :commentable, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  has_one_attached :cover_image do |attachable|
    attachable.variant :hero,  resize_to_limit: [ 1600, 800 ], format: :webp, saver: { quality: 85 }
    attachable.variant :card,  resize_to_limit: [ 800, 450 ],  format: :webp, saver: { quality: 80 }
    attachable.variant :thumb, resize_to_limit: [ 200, 140 ],  format: :webp, saver: { quality: 75 }
  end

  enum :status, { draft: 0, published: 1 }
  enum :category, {
    internship: 0,
    full_time: 1,
    part_time: 2,
    contract: 3,
    government: 4,
    other_job: 5,
    new_job_news: 6
  }, prefix: :category

  validates :title_en,       presence: true
  validates :description_en, presence: true
  validates :company_name, presence: true

  scope :visible, -> { published.order(published_at: :desc, created_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def category_label
    category.humanize
  end

  def deadline_passed?
    deadline.present? && deadline < Date.current
  end
end
