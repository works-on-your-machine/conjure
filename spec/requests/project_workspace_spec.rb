require "rails_helper"

RSpec.describe "Project Workspace", type: :request do
  let!(:grimoire) { create(:grimoire, name: "Pirate Broadcast") }
  let!(:other_grimoire) { create(:grimoire, name: "Bauhaus Clean") }
  let!(:project) { create(:project, name: "My Talk", source_grimoire: grimoire) }

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
      expect(response.body).to include("project[grimoire_attributes][description]")
    end

    it "only shows the project's grimoire" do
      get grimoire_project_path(project)
      expect(response.body).to include("Pirate Broadcast")
      expect(response.body).not_to include("Bauhaus Clean")
    end

    it "shows variation count selector" do
      get grimoire_project_path(project)
      expect(response.body).to include("5") # default
    end
  end

  describe "PATCH /projects/:id" do
    it "does not switch the source grimoire" do
      patch project_path(project), params: { project: { source_grimoire_id: other_grimoire.id } }
      expect(response).to redirect_to(grimoire_project_path(project))
      expect(project.reload.source_grimoire).to eq(grimoire)
    end

    it "updates default variations" do
      patch project_path(project), params: { project: { default_variations: 12 } }
      expect(response).to redirect_to(grimoire_project_path(project))
      expect(project.reload.default_variations).to eq(12)
    end

    it "updates the grimoire text" do
      patch project_path(project), params: {
        project: {
          grimoire_attributes: {
            id: project.grimoire.id,
            description: "Neon scanlines and pirate TV graphics."
          }
        }
      }

      expect(response).to redirect_to(grimoire_project_path(project))
      expect(project.reload.grimoire.description).to eq("Neon scanlines and pirate TV graphics.")
      expect(grimoire.reload.description).not_to eq("Neon scanlines and pirate TV graphics.")
    end
  end
end
