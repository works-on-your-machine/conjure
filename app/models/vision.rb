class Vision < ApplicationRecord
  belongs_to :slide
  belongs_to :conjuring
  has_one_attached :image

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }

  after_update_commit :broadcast_tile_replacement, if: :status_just_completed?

  def self.total_storage_bytes
    ActiveStorage::Blob.joins(:attachments)
      .where(active_storage_attachments: { record_type: "Vision" })
      .sum(:byte_size)
  end

  private

  def status_just_completed?
    complete? && status_previously_changed?
  end

  def broadcast_tile_replacement
    project = conjuring.project
    # Replace vision tile on visions page (no-op if not on that page)
    Turbo::StreamsChannel.broadcast_replace_to(
      project,
      target: "vision_tile_#{id}",
      partial: "visions/vision_tile",
      locals: { vision: self, project: project, revealed: false }
    )
  end
end
