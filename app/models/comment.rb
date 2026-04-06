class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true, counter_cache: true, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }

  scope :recent, -> { order(created_at: :desc) }
end
