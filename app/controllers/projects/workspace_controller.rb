class Projects::WorkspaceController < ApplicationController
  before_action :set_project

  def grimoire
    render_workspace("grimoire")
  end

  def incantations
    render_workspace("incantations")
  end

  def visions
    render_workspace("visions")
  end

  def assembly
    render_workspace("assembly")
  end

  def refine
    render_workspace("refine")
  end

  private

  def render_workspace(section)
    render "projects/show", locals: { section: section }
  end

  def set_project
    @project = Project.includes(:grimoire, :slides).find(params[:id])
  end
end
