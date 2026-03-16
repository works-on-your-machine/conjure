class SlidesController < ApplicationController
  before_action :set_project
  before_action :set_slide, only: [ :edit, :update, :destroy, :move ]

  def create
    next_position = @project.slides.maximum(:position).to_i + 1
    @slide = @project.slides.build(slide_params.merge(position: next_position))
    @slide.save!
    redirect_to project_path(@project, section: "incantations")
  end

  def edit
  end

  def update
    @slide.update!(slide_params)
    redirect_to project_path(@project, section: "incantations")
  end

  def destroy
    @slide.destroy
    redirect_to project_path(@project, section: "incantations")
  end

  def move
    direction = params[:direction]
    if direction == "up" && @slide.position > 1
      swap_with = @project.slides.find_by(position: @slide.position - 1)
      swap_positions(@slide, swap_with) if swap_with
    elsif direction == "down"
      swap_with = @project.slides.find_by(position: @slide.position + 1)
      swap_positions(@slide, swap_with) if swap_with
    end
    redirect_to project_path(@project, section: "incantations")
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_slide
    @slide = @project.slides.find(params[:id])
  end

  def slide_params
    params.require(:slide).permit(:title, :description)
  end

  def swap_positions(a, b)
    a_pos = a.position
    b_pos = b.position
    a.update!(position: b_pos)
    b.update!(position: a_pos)
  end
end
