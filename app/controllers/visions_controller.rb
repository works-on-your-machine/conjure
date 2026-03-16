class VisionsController < ApplicationController
  before_action :set_project
  before_action :set_vision

  def show
  end

  def update
    @vision.update!(vision_params)
    redirect_to project_path(@project, section: "visions")
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
