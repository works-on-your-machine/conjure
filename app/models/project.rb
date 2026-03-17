class Project < ApplicationRecord
  belongs_to :grimoire, inverse_of: :owned_project, dependent: :destroy
  belongs_to :source_grimoire, class_name: "Grimoire", optional: true, counter_cache: :projects_count, inverse_of: :projects
  accepts_nested_attributes_for :grimoire
  has_many :slides, -> { order(:position) }, dependent: :destroy
  has_many :conjurings, dependent: :destroy
  has_many :visions, through: :conjurings

  validates :name, presence: true
  validates :source_grimoire, presence: true, on: :create

  before_validation :build_grimoire_from_source, on: :create

  private

  def build_grimoire_from_source
    return if grimoire.present? || source_grimoire.blank?

    self.grimoire = source_grimoire.dup.tap do |copy|
      copy.projects_count = 0
    end
  end
end
