class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :update, :destroy ]

  def index
    @projects = Project.includes(:grimoire, slides: { visions: { image_attachment: :blob } }).order(updated_at: :desc)
  end

  def show
    redirect_to grimoire_project_path(@project)
  end

  def update
    if @project.update(update_project_params)
      redirect_to grimoire_project_path(@project)
    else
      render :show, locals: { section: "grimoire" }, status: :unprocessable_entity
    end
  end

  def new
    @project = Project.new(
      name: params.dig(:project, :name),
      source_grimoire_id: params[:source_grimoire_id] || params[:grimoire_id]
    )
    @grimoires = Grimoire.library
  end

  def create
    @project = Project.new(create_project_params)
    if @project.save
      redirect_to grimoire_project_path(@project)
    else
      @grimoires = Grimoire.library
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to root_path
  end

  private

  def set_project
    @project = Project.includes(:grimoire, :slides).find(params[:id])
  end

  def create_project_params
    params.require(:project).permit(:name, :source_grimoire_id, :default_variations).tap do |attributes|
      legacy_grimoire_id = params.dig(:project, :grimoire_id)
      attributes[:source_grimoire_id] ||= legacy_grimoire_id if legacy_grimoire_id.present?
    end
  end

  def update_project_params
    params.require(:project).permit(:default_variations, :slide_prompt, grimoire_attributes: [ :id, :description ])
  end
end
