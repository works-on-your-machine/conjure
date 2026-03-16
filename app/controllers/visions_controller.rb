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

    # Re-render the slide row Turbo Frame
    @slide = @vision.slide.reload
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "slide_#{@slide.id}_row",
          partial: "visions/slide_row",
          locals: { slide: @slide, project: @project }
        )
      }
      format.html { redirect_to project_path(@project, section: "visions") }
    end
  end

  def destroy
    slide = @vision.slide
    @vision.destroy

    @slide = slide.reload
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "slide_#{@slide.id}_row",
          partial: "visions/slide_row",
          locals: { slide: @slide, project: @project }
        )
      }
      format.html { redirect_to project_path(@project, section: "visions") }
    end
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
