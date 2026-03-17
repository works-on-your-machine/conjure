class ProjectsController < ApplicationController
  before_action :set_project, only: [ :grimoire, :incantations, :visions, :assembly, :refine, :update, :destroy ]

  def index
    @projects = Project.includes(:grimoire, slides: { visions: { image_attachment: :blob } }).order(updated_at: :desc)
  end

  def grimoire
    render :show, locals: { section: "grimoire" }
  end

  def incantations
    render :show, locals: { section: "incantations" }
  end

  def visions
    render :show, locals: { section: "visions" }
  end

  def assembly
    render :show, locals: { section: "assembly" }
  end

  def refine
    render :show, locals: { section: "refine" }
  end

  def update
    if @project.update(update_project_params)
      redirect_to grimoire_project_path(@project)
    else
      render :show, locals: { section: "grimoire" }, status: :unprocessable_entity
    end
  end

  def new
    @project = Project.new
    @grimoires = Grimoire.all
  end

  def create
    @project = Project.new(create_project_params)
    if @project.save
      redirect_to grimoire_project_path(@project)
    else
      @grimoires = Grimoire.all
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
    params.require(:project).permit(:name, :grimoire_id, :default_variations)
  end

  def update_project_params
    params.require(:project).permit(:default_variations, grimoire_attributes: [ :id, :description ])
  end
end
