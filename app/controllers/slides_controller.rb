class SlidesController < ApplicationController
  before_action :set_project
  before_action :set_slide, only: [ :edit, :update, :destroy, :move ]

  def create
    if params[:outline].present?
      generate_from_outline(params[:outline])
    else
      title = params.dig(:slide, :title) || params[:title]
      next_position = @project.slides.maximum(:position).to_i + 1
      @slide = @project.slides.create!(title: title, description: "", position: next_position)
    end
    redirect_to incantations_project_path(@project)
  end

  def edit
  end

  def update
    @slide.update!(slide_params)
    redirect_to incantations_project_path(@project)
  end

  def destroy
    @slide.destroy
    redirect_to incantations_project_path(@project)
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
    redirect_to incantations_project_path(@project)
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

  def generate_from_outline(outline_text)
    service = OutlineToSlidesService.new(api_key: Setting.current.llm_api_key)
    slides_data = service.generate(outline_text)

    next_position = @project.slides.maximum(:position).to_i + 1
    slides_data.each_with_index do |data, i|
      @project.slides.create!(
        title: data[:title],
        description: data[:description],
        position: next_position + i
      )
    end
  end

  def swap_positions(a, b)
    a_pos = a.position
    b_pos = b.position
    a.update!(position: b_pos)
    b.update!(position: a_pos)
  end
end
