class Vision < ApplicationRecord
  belongs_to :slide
  belongs_to :conjuring
  has_one_attached :image

  def self.total_storage_bytes
    ActiveStorage::Blob.joins(:attachments)
      .where(active_storage_attachments: { record_type: "Vision" })
      .sum(:byte_size)
  end
end
