require "rails_helper"

RSpec.describe "New Project", type: :request do
  let!(:grimoire) { create(:grimoire) }

  describe "GET /projects/new" do
    it "renders the new project form" do
      get new_project_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("project")
    end

    it "shows available grimoires for selection" do
      get new_project_path
      expect(response.body).to include(grimoire.name)
    end
  end

  describe "POST /projects" do
    it "creates a project and redirects to workspace" do
      expect {
        post projects_path, params: { project: { name: "My Talk", grimoire_id: grimoire.id } }
      }.to change(Project, :count).by(1)

      project = Project.last
      expect(project.name).to eq("My Talk")
      expect(project.grimoire).to eq(grimoire)
      expect(response).to redirect_to(grimoire_project_path(project))
    end

    it "fails without a name" do
      post projects_path, params: { project: { name: "", grimoire_id: grimoire.id } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "fails without a grimoire" do
      post projects_path, params: { project: { name: "No Grimoire" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /projects/:id" do
    it "deletes the project and redirects to workshop" do
      project = create(:project)

      expect {
        delete project_path(project)
      }.to change(Project, :count).by(-1)

      expect(response).to redirect_to(root_path)
    end
  end
end
