class Relative < ApplicationRecord
  TYPES = %w[Bhaiya Bhabhi Mama Mami Chacha Chachi Dada Dadi Nana Nani Jijaji Didi Behan].freeze

  belongs_to :biodata

  validates :relative_type, inclusion: { in: TYPES }
  validates :name, presence: true
end
