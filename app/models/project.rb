class Project < ApplicationRecord
  belongs_to :grimoire, counter_cache: true
  has_many :slides, -> { order(:position) }, dependent: :destroy
  has_many :conjurings, dependent: :destroy
  has_many :visions, through: :conjurings

  validates :name, presence: true
end
