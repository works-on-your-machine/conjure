class ConjuringsController < ApplicationController
  before_action :set_project

  def create
    @conjuring = @project.conjurings.build(
      grimoire_text: @project.grimoire.description,
      variations_count: @project.default_variations,
      status: :pending
    )
    @conjuring.save!
    ConjuringJob.perform_later(@conjuring)
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
