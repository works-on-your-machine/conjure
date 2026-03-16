class Conjuring < ApplicationRecord
  belongs_to :project
  has_many :visions, dependent: :destroy

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }

  validates :grimoire_text, presence: true
  validates :variations_count, presence: true
end
