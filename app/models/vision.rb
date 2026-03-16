class Vision < ApplicationRecord
  belongs_to :slide
  belongs_to :conjuring
  has_one_attached :image

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }

  def self.total_storage_bytes
    ActiveStorage::Blob.joins(:attachments)
      .where(active_storage_attachments: { record_type: "Vision" })
      .sum(:byte_size)
  end
end
