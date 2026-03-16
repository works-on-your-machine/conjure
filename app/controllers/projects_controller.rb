class ProjectsController < ApplicationController
  def index
    @projects = Project.includes(:grimoire, :slides).order(updated_at: :desc)
  end

  def show
    @project = Project.includes(:grimoire, :slides).find(params[:id])
  end
end
