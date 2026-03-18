class ConjuringsController < ApplicationController
  before_action :set_project

  def create
    scope = params[:scope] || params.dig(:conjuring, :scope) || "all"

    variations = (params[:variations] || params.dig(:conjuring, :variations) || @project.default_variations).to_i
    @project.update!(default_variations: variations) if variations != @project.default_variations

    @conjuring = @project.conjurings.build(
      grimoire_text: @project.grimoire.description,
      variations_count: variations,
      status: :pending
    )
    @conjuring.save!

    slide_id = params[:slide_id] || params.dig(:conjuring, :slide_id)

    case scope
    when "refine"
      refinement = params[:refinement] || params.dig(:conjuring, :refinement)
      ConjuringJob.perform_later(@conjuring, slide_ids: [ slide_id.to_i ], refinement: refinement)
    when "single"
      ConjuringJob.perform_later(@conjuring, slide_ids: [ slide_id.to_i ])
    when "empty"
      empty_slide_ids = @project.slides.left_joins(:visions).where(visions: { id: nil }).pluck(:id)
      ConjuringJob.perform_later(@conjuring, slide_ids: empty_slide_ids)
    else
      ConjuringJob.perform_later(@conjuring)
    end

    redirect_back = params[:redirect_to] || params.dig(:conjuring, :redirect_to)
    if redirect_back == "incantations"
      redirect_to incantations_project_path(@project)
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
