class Shortlist < ApplicationRecord
  belongs_to :user
  belongs_to :biodata
  validates :biodata_id, uniqueness: { scope: :user_id }
end
