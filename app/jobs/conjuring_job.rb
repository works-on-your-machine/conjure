class ConjuringJob < ApplicationJob
  queue_as :default

  def perform(conjuring)
    conjuring.generating!

    prompt_service = PromptAssemblyService.new(
      api_key: Setting.current.llm_api_key
    )

    conjuring.project.slides.each do |slide|
      prompt = prompt_service.assemble(
        grimoire_text: conjuring.grimoire_text,
        slide_text: slide.description
      )

      conjuring.variations_count.times do |i|
        vision = Vision.create!(
          slide: slide,
          conjuring: conjuring,
          position: i + 1,
          slide_text: slide.description,
          prompt: prompt,
          status: :pending
        )

        VisionGenerationJob.perform_later(vision)
      end
    end
  rescue => e
    conjuring.failed!
    Rails.logger.error("ConjuringJob failed: #{e.message}")
  end
end
