class ConjuringJob < ApplicationJob
  queue_as :default

  def perform(conjuring, slide_ids: nil, refinement: nil, source_vision_id: nil)
    conjuring.generating!

    slides = if slide_ids.present?
      conjuring.project.slides.where(id: slide_ids)
    else
      conjuring.project.slides
    end

    slides.each do |slide|
      # For refine with a source image, use a direct edit prompt
      # For normal generation, use the full prompt assembly service
      if refinement.present? && source_vision_id.present?
        prompt = "Edit this presentation slide image. #{refinement}"
      else
        prompt_service = PromptAssemblyService.new(
          api_key: Setting.current.llm_api_key
        )
        prompt = prompt_service.assemble(
          grimoire_text: conjuring.grimoire_text,
          slide_text: slide.description,
          refinement: refinement,
          slide_prompt: conjuring.project.slide_prompt
        )
      end

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

        Turbo::StreamsChannel.broadcast_append_to(
          "project_#{conjuring.project_id}_visions",
          target: "slide_#{slide.id}_visions",
          partial: "visions/vision_tile",
          locals: { vision: vision, project: conjuring.project, revealed: true }
        )

        VisionGenerationJob.perform_later(vision, source_vision_id: source_vision_id)
      end
    end
  rescue => e
    conjuring.failed!
    Rails.logger.error("ConjuringJob failed: #{e.message}")
  end
end
