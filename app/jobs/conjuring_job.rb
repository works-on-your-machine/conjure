class ConjuringJob < ApplicationJob
  queue_as :default

  def perform(conjuring, slide_ids: nil, refinement: nil)
    conjuring.generating!

    prompt_service = PromptAssemblyService.new(
      api_key: Setting.current.llm_api_key
    )

    slides = if slide_ids.present?
      conjuring.project.slides.where(id: slide_ids)
    else
      conjuring.project.slides
    end

    slides.each do |slide|
      prompt = prompt_service.assemble(
        grimoire_text: conjuring.grimoire_text,
        slide_text: slide.description,
        refinement: refinement
      )

      conjuring.variations_count.times do |i|
        vision = Vision.create!(
          slide: slide,
          conjuring: conjuring,
          position: i + 1,
          slide_text: slide.description,
          prompt: prompt,
          refinement: refinement,
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
