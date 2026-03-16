class VisionsController < ApplicationController
  before_action :set_project
  before_action :set_vision

  def show
  end

  def update
    # Single selection per slide: deselect others when selecting
    if vision_params[:selected] == "true" || vision_params[:selected] == true
      @vision.slide.visions.where.not(id: @vision.id).where(selected: true).update_all(selected: false)
    end

    @vision.update!(vision_params)
    respond_to do |format|
      format.html { redirect_to project_path(@project, section: "visions") }
      format.json { head :ok }
      format.turbo_stream { head :ok }
    end
  end

  def destroy
    @vision.destroy
    redirect_to project_path(@project, section: "visions")
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_vision
    @vision = @project.visions.find(params[:id])
  end

  def vision_params
    params.require(:vision).permit(:selected)
  end
end
