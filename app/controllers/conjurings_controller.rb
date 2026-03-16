class ConjuringsController < ApplicationController
  before_action :set_project

  def create
    scope = params[:scope] || params.dig(:conjuring, :scope) || "all"

    @conjuring = @project.conjurings.build(
      grimoire_text: @project.grimoire.description,
      variations_count: @project.default_variations,
      status: :pending
    )
    @conjuring.save!

    case scope
    when "refine"
      slide_id = params[:slide_id] || params.dig(:conjuring, :slide_id)
      refinement = params[:refinement] || params.dig(:conjuring, :refinement)
      ConjuringJob.perform_later(@conjuring, slide_ids: [ slide_id.to_i ], refinement: refinement)
    when "empty"
      empty_slide_ids = @project.slides.left_joins(:visions).where(visions: { id: nil }).pluck(:id)
      ConjuringJob.perform_later(@conjuring, slide_ids: empty_slide_ids)
    else
      ConjuringJob.perform_later(@conjuring)
    end

    redirect_to project_path(@project, section: "visions")
  end

  def destroy
    conjuring = @project.conjurings.find(params[:id])
    conjuring.destroy
    redirect_to project_path(@project, section: "visions")
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
