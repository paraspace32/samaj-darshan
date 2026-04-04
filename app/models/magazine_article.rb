class MagazineArticle < ApplicationRecord
  include Bilingual
  bilingual_field :title, :content

  belongs_to :magazine
  belongs_to :author, class_name: "User"

  has_one_attached :cover_image do |attachable|
    attachable.variant :card,  resize_to_limit: [ 800, 450 ], format: :webp, saver: { quality: 90 }
    attachable.variant :thumb, resize_to_limit: [ 200, 140 ], format: :webp, saver: { quality: 85 }
  end

  validates :title_en, presence: true
  validates :title_hi, presence: true
  validates :content_en, presence: true
  validates :content_hi, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(position: :asc) }
end
