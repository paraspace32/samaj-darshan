class Tribute < ApplicationRecord
  include Bilingual
  bilingual_field :name, :description

  belongs_to :created_by, class_name: "User"
  has_many :flowers, dependent: :destroy
  has_many :flower_givers, through: :flowers, source: :user

  has_one_attached :image do |attachable|
    attachable.variant :hero,  resize_to_limit: [ 1200, 800 ], format: :webp, saver: { quality: 85 }
    attachable.variant :card,  resize_to_limit: [ 600, 400 ],  format: :webp, saver: { quality: 80 }
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ],  format: :webp, saver: { quality: 75 }
    attachable.variant :og,    resize_to_fill: [ 1200, 630 ],  format: :jpeg, saver: { quality: 80 }
  end

  validates :name_en, presence: true
  validates :description_en, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
