class Grimoire < ApplicationRecord
  has_one :owned_project, class_name: "Project", foreign_key: :grimoire_id, inverse_of: :grimoire
  has_many :projects, class_name: "Project", foreign_key: :source_grimoire_id, inverse_of: :source_grimoire, dependent: :nullify

  validates :name, presence: true

  scope :library, -> { where.missing(:owned_project).order(:name) }
end
