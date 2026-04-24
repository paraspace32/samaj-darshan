class EducationPost < ApplicationRecord
  include Bilingual
  bilingual_field :title, :content

  belongs_to :author, class_name: "User"

  has_many :comments, as: :commentable, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  has_one_attached :cover_image do |attachable|
    attachable.variant :hero,  resize_to_limit: [ 1600, 800 ], format: :webp, saver: { quality: 85 }
    attachable.variant :card,  resize_to_limit: [ 800, 450 ],  format: :webp, saver: { quality: 80 }
    attachable.variant :thumb, resize_to_limit: [ 200, 140 ],  format: :webp, saver: { quality: 75 }
    attachable.variant :og,    resize_to_limit: [ 1200, 630 ], format: :jpeg, saver: { quality: 80 }
  end

  enum :status, { draft: 0, published: 1 }
  enum :category, {
    competitive_exam: 0,
    board_exam: 1,
    entrance_exam: 2,
    scholarship: 3,
    result: 4,
    other_education: 5,
    degree_news: 6
  }, prefix: :category

  validates :title_en,   presence: true
  validates :content_en, presence: true

  scope :visible, -> { published.order(published_at: :desc, created_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def category_label
    category.humanize
  end
end
