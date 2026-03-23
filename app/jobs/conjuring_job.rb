class ConjuringJob < ApplicationJob
  queue_as :default

  def perform(conjuring, slide_ids: nil, refinement: nil, source_vision_id: nil)
    conjuring.generating!

    project = conjuring.project

    slides = if slide_ids.present?
      project.slides.where(id: slide_ids)
    else
      project.slides
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
          slide_prompt: project.slide_prompt
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

        # Append pending tile to visions page grid (no-op on other pages)
        Turbo::StreamsChannel.broadcast_append_to(
          project,
          target: "slide_#{slide.id}_visions",
          partial: "visions/vision_tile",
          locals: { vision: vision, project: project, revealed: true }
        )
      end

      # Show "Refining..." placeholder on assembly page (no-op on other pages)
      if refinement.present?
        broadcast_assembly_slide(project, slide)
      end

      slide.visions.pending.each do |vision|
        VisionGenerationJob.perform_later(vision, source_vision_id: source_vision_id)
      end
    end
  rescue => e
    conjuring.failed!
    Rails.logger.error("ConjuringJob failed: #{e.message}")
  end

  private

  def broadcast_assembly_slide(project, slide)
    index = project.slides.order(:position).pluck(:id).index(slide.id) || 0
    Turbo::StreamsChannel.broadcast_replace_to(
      project,
      target: "assembly_slide_#{slide.id}",
      partial: "assembly/slide_row",
      locals: { slide: slide.reload, project: project, index: index }
    )
  end
end
