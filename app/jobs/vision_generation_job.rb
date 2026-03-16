class VisionGenerationJob < ApplicationJob
  queue_as :default

  # Retry on rate limits with exponential backoff (5 attempts over ~5 min)
  retry_on GeminiImageProvider::RateLimitError, wait: :polynomially_longer, attempts: 5

  # Retry on server errors with backoff (3 attempts)
  retry_on GeminiImageProvider::ServerError, wait: :polynomially_longer, attempts: 3

  def perform(vision)
    vision.generating!

    provider = GeminiImageProvider.new(
      api_key: Setting.current.nano_banana_api_key
    )

    result = provider.generate(
      prompt: vision.prompt,
      aspect_ratio: vision.conjuring.project.aspect_ratio
    )

    vision.image.attach(
      io: StringIO.new(Base64.decode64(result[:image_data])),
      filename: "vision_#{vision.id}.png",
      content_type: result[:mime_type]
    )

    vision.complete!
    check_conjuring_completion(vision.conjuring)
  rescue GeminiImageProvider::ClientError => e
    vision.failed!
    Rails.logger.error("VisionGenerationJob failed (client error, no retry): #{e.message}")
    check_conjuring_completion(vision.conjuring)
  end

  private

  def check_conjuring_completion(conjuring)
    return unless conjuring.generating?

    visions = conjuring.visions.reload
    return if visions.any?(&:pending?) || visions.any?(&:generating?)

    if visions.all?(&:failed?)
      conjuring.failed!
    else
      conjuring.complete!
    end
  end
end
