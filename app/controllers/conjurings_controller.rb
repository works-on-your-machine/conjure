class ConjuringsController < ApplicationController
  before_action :set_project

  def create
    scope = params[:scope] || params.dig(:conjuring, :scope) || "all"

    slide_id = params[:slide_id] || params.dig(:conjuring, :slide_id)
    refinement = params[:refinement] || params.dig(:conjuring, :refinement)

    # Refine always generates exactly 1 variation
    if scope == "refine"
      variations = 1
    else
      variations = (params[:variations] || params.dig(:conjuring, :variations) || @project.default_variations).to_i
      @project.update!(default_variations: variations) if variations != @project.default_variations
    end

    @conjuring = @project.conjurings.build(
      grimoire_text: @project.grimoire.description,
      variations_count: variations,
      status: :pending
    )
    @conjuring.save!

    case scope
    when "refine"
      source_vision_id = params[:source_vision_id] || params.dig(:conjuring, :source_vision_id)
      ConjuringJob.perform_later(@conjuring, slide_ids: [ slide_id.to_i ], refinement: refinement, source_vision_id: source_vision_id&.to_i)
    when "single"
      ConjuringJob.perform_later(@conjuring, slide_ids: [ slide_id.to_i ])
    when "empty"
      empty_slide_ids = @project.slides.left_joins(:visions).where(visions: { id: nil }).pluck(:id)
      ConjuringJob.perform_later(@conjuring, slide_ids: empty_slide_ids)
    else
      ConjuringJob.perform_later(@conjuring)
    end

    redirect_back = params[:redirect_to] || params.dig(:conjuring, :redirect_to)
    # Refine defaults to assembly page unless explicitly overridden
    redirect_back ||= "assembly" if scope == "refine"
    case redirect_back
    when "incantations"
      redirect_to incantations_project_path(@project)
    when "assembly"
      redirect_to assembly_project_path(@project)
    when "stay"
      # Stay on current page — turbo stream broadcasts handle the UI update
      streams = []
      if scope != "refine" && (params[:slide_id] || params.dig(:conjuring, :slide_id))
        streams << turbo_stream.update("slide_conjuring_status", html:
          '<div class="mt-3"><div class="flex items-center gap-2 text-xs text-gold">' \
          '<div class="w-3 h-3 border border-gold-glow border-t-gold rounded-full animate-spin"></div>' \
          "#{variations} #{'vision'.pluralize(variations)} summoning..." \
          "</div></div>")
      end
      render turbo_stream: streams
    else
      redirect_to visions_project_path(@project)
    end
  end

  def destroy
    conjuring = @project.conjurings.find(params[:id])
    conjuring.destroy
    redirect_to visions_project_path(@project)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
