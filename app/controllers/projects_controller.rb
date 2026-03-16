class ProjectsController < ApplicationController
  def index
    @projects = Project.includes(:grimoire, :slides).order(updated_at: :desc)
  end

  def show
    @project = Project.includes(:grimoire, :slides).find(params[:id])
    @grimoires = Grimoire.all
  end

  def update
    @project = Project.find(params[:id])
    @project.update!(project_params)
    redirect_to project_path(@project)
  end

  def new
    @project = Project.new
    @grimoires = Grimoire.all
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to @project
    else
      @grimoires = Grimoire.all
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to root_path
  end

  private

  def project_params
    params.require(:project).permit(:name, :grimoire_id, :default_variations)
  end
end
