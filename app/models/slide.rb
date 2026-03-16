class Slide < ApplicationRecord
  belongs_to :project

  validates :title, presence: true
  validates :position, presence: true
end
