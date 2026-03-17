class Vision < ApplicationRecord
  belongs_to :slide
  belongs_to :conjuring
  has_one_attached :image

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }

  after_update_commit :broadcast_completion, if: :status_just_completed?

  private

  def status_just_completed?
    complete? && status_previously_changed?
  end

  def broadcast_completion
    project = conjuring.project
    Turbo::StreamsChannel.broadcast_append_to(
      "project_#{project.id}_visions",
      target: "slide_#{slide_id}_visions",
      partial: "visions/vision",
      locals: { vision: self, revealed: false }
    )
  end

  def self.total_storage_bytes
    ActiveStorage::Blob.joins(:attachments)
      .where(active_storage_attachments: { record_type: "Vision" })
      .sum(:byte_size)
  end
end
