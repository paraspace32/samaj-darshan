class Magazine < ApplicationRecord
  include Bilingual
  bilingual_field :title, :description

  has_many :magazine_articles, -> { order(position: :asc) }, dependent: :destroy

  has_one_attached :cover_image do |attachable|
    attachable.variant :hero,  resize_to_limit: [ 1600, 800 ], format: :webp, saver: { quality: 92 }
    attachable.variant :card,  resize_to_limit: [ 800, 450 ],  format: :webp, saver: { quality: 90 }
    attachable.variant :thumb, resize_to_limit: [ 300, 400 ],  format: :webp, saver: { quality: 85 }
  end

  enum :status, { draft: 0, published: 1 }

  validates :title_en, presence: true
  validates :title_hi, presence: true
  validates :issue_number, presence: true, uniqueness: true, numericality: { greater_than: 0 }

  scope :visible, -> { published.order(published_at: :desc) }
  scope :recent, -> { order(issue_number: :desc) }

  def display_issue
    vol = volume.present? ? "Vol. #{volume}, " : ""
    "#{vol}Issue ##{issue_number}"
  end

  def publish!
    update!(status: :published, published_at: Time.current)
  end
end
