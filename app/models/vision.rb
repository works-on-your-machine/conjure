class Vision < ApplicationRecord
  belongs_to :slide
  belongs_to :conjuring
  has_one_attached :image

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }

  after_create_commit :broadcast_project_refresh
  after_update_commit :broadcast_project_refresh

  def self.total_storage_bytes
    ActiveStorage::Blob.joins(:attachments)
      .where(active_storage_attachments: { record_type: "Vision" })
      .sum(:byte_size)
  end

  private

  def broadcast_project_refresh
    project = conjuring&.project
    return unless project
    Turbo::StreamsChannel.broadcast_refresh_later_to(project)
  end
end
