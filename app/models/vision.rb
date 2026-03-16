class Vision < ApplicationRecord
  belongs_to :slide
  belongs_to :conjuring
  has_one_attached :image
end
