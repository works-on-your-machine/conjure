class Slide < ApplicationRecord
  belongs_to :project
  has_many :visions, dependent: :destroy

  validates :title, presence: true
  validates :position, presence: true
end
