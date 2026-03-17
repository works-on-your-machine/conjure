class Project < ApplicationRecord
  belongs_to :grimoire, counter_cache: true
  accepts_nested_attributes_for :grimoire
  has_many :slides, -> { order(:position) }, dependent: :destroy
  has_many :conjurings, dependent: :destroy
  has_many :visions, through: :conjurings

  validates :name, presence: true
end
