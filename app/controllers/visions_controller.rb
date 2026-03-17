class VisionsController < ApplicationController
  before_action :set_project
  before_action :set_vision, only: [ :show, :update, :destroy ]

  def show
  end

  def update
    # Single selection per slide: deselect others when selecting
    if vision_params[:selected] == "true" || vision_params[:selected] == true
      @vision.slide.visions.where.not(id: @vision.id).where(selected: true).update_all(selected: false)
    end

    @vision.update!(vision_params)
    replace_slide_row(@vision.slide)
  end

  def destroy
    slide = @vision.slide
    @vision.destroy
    replace_slide_row(slide)
  end

  private

  def replace_slide_row(slide)
    slide.reload
    open_slides = params[:open_slide].present? ? Set.new([ params[:open_slide].to_i ]) : Set.new

    @project.reload

    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: [
          turbo_stream.replace(
            "slide_#{slide.id}_row",
            partial: "visions/slide_row",
            locals: { slide: slide, project: @project, open_slides: open_slides }
          ),
          turbo_stream.replace(
            "visions-header",
            partial: "visions/header",
            locals: { project: @project }
          )
        ]
      }
      format.html { redirect_to visions_project_path(@project) }
    end
  end

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
