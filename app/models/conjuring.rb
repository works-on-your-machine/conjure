class Conjuring < ApplicationRecord
  belongs_to :project
  has_many :visions, dependent: :destroy

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }

  validates :grimoire_text, presence: true
  validates :variations_count, presence: true

  after_update_commit :broadcast_status_change

  private

  def broadcast_status_change
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{project_id}_conjuring",
      target: "conjuring_#{id}_status",
      html: "<span id=\"conjuring_#{id}_status\" class=\"text-xs\">#{status}</span>"
    )
  end
end
