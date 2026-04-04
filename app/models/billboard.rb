class Billboard < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :banner, resize_to_limit: [ 1600, 500 ], format: :webp, saver: { quality: 92 }
    attachable.variant :card,   resize_to_limit: [ 800, 400 ],  format: :webp, saver: { quality: 90 }
    attachable.variant :splash, resize_to_limit: [ 1600, 1200 ], format: :webp, saver: { quality: 92 }
    attachable.variant :thumb,  resize_to_limit: [ 300, 180 ],   format: :webp, saver: { quality: 85 }
  end

  enum :billboard_type, { top_banner: 0, feed_inline: 1, fullscreen_splash: 2, article_top: 3, article_mid: 4 }

  validates :title, presence: true
  validates :billboard_type, presence: true
  validates :image, presence: true, on: :create

  scope :live, -> {
    where(active: true)
      .where("start_date IS NULL OR start_date <= ?", Date.current)
      .where("end_date IS NULL OR end_date >= ?", Date.current)
  }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }

  def self.for_position(position)
    live.where(billboard_type: position).by_priority.first
  end

  def self.all_for_position(position)
    live.where(billboard_type: position).by_priority
  end

  def live?
    active? &&
      (start_date.nil? || start_date <= Date.current) &&
      (end_date.nil? || end_date >= Date.current)
  end

  def track_impression!
    increment!(:impressions_count)
  end

  def track_click!
    increment!(:clicks_count)
  end
end
