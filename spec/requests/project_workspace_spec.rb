require "rails_helper"

RSpec.describe "Project Workspace", type: :request do
  let!(:grimoire) { create(:grimoire, name: "Pirate Broadcast") }
  let!(:other_grimoire) { create(:grimoire, name: "Bauhaus Clean") }
  let!(:project) { create(:project, name: "My Talk", grimoire: grimoire) }

  describe "GET /projects/:id/grimoire (Grimoire section)" do
    it "shows the project name and grimoire" do
      get grimoire_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Talk")
      expect(response.body).to include("Pirate Broadcast")
    end

    it "displays the grimoire description as editable text" do
      get grimoire_project_path(project)
      expect(response.body).to include(grimoire.description)
    end

    it "shows all grimoires for switching" do
      get grimoire_project_path(project)
      expect(response.body).to include("Pirate Broadcast")
      expect(response.body).to include("Bauhaus Clean")
    end

    it "shows variation count selector" do
      get grimoire_project_path(project)
      expect(response.body).to include("5") # default
    end
  end

  describe "PATCH /projects/:id" do
    it "switches the grimoire" do
      patch project_path(project), params: { project: { grimoire_id: other_grimoire.id } }
      expect(response).to redirect_to(grimoire_project_path(project))
      expect(project.reload.grimoire).to eq(other_grimoire)
    end

    it "updates default variations" do
      patch project_path(project), params: { project: { default_variations: 12 } }
      expect(response).to redirect_to(grimoire_project_path(project))
      expect(project.reload.default_variations).to eq(12)
    end
  end
end
