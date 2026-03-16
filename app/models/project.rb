class Project < ApplicationRecord
  belongs_to :grimoire, counter_cache: true

  validates :name, presence: true
end
