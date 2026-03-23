class Conjuring < ApplicationRecord
  belongs_to :project
  has_many :visions, dependent: :destroy

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }

  validates :grimoire_text, presence: true
  validates :variations_count, presence: true

  after_update_commit :broadcast_project_refresh

  # Per-project run number (1-based position among project's conjurings)
  def run_number
    project.conjurings.where("id <= ?", id).count
  end

  private

  def broadcast_project_refresh
    Turbo::StreamsChannel.broadcast_refresh_later_to(project)
  end
end
