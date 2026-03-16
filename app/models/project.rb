class Project < ApplicationRecord
  belongs_to :grimoire, counter_cache: true
  has_many :slides, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true
end
