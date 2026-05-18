class Flower < ApplicationRecord
  belongs_to :tribute, counter_cache: true
  belongs_to :user

  validates :user_id, uniqueness: { scope: :tribute_id, message: "has already given flowers" }
end
