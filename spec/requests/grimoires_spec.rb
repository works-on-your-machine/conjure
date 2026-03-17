require "rails_helper"

RSpec.describe "Grimoires", type: :request do
  describe "GET /grimoires" do
    it "renders the grimoire library" do
      create(:grimoire, name: "Pirate Broadcast")
      create(:grimoire, name: "Bauhaus Clean")

      get grimoires_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Grimoire Library")
      expect(response.body).to include("Pirate Broadcast")
      expect(response.body).to include("Bauhaus Clean")
    end

    it "shows usage count for each grimoire" do
      grimoire = create(:grimoire)
      create(:project, source_grimoire: grimoire)
      create(:project, source_grimoire: grimoire, name: "Second Deck")

      get grimoires_path
      expect(response.body).to include("2 projects")
    end

    it "shows description preview" do
      create(:grimoire, description: "VHS static. CRT monitors with scan lines.")

      get grimoires_path
      expect(response.body).to include("VHS static")
    end
  end

  describe "GET /grimoires/new" do
    it "renders the create form" do
      get new_grimoire_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create new grimoire")
    end

    it "links back to the project flow when opened from new project" do
      get new_grimoire_path, params: { return_to_project: "1", project: { name: "My Talk" } }

      expect(response.body).to include(new_project_path(project: { name: "My Talk" }))
      expect(response.body).to include("Back to project")
    end
  end

  describe "POST /grimoires" do
    it "creates a grimoire and redirects to show" do
      expect {
        post grimoires_path, params: { grimoire: { name: "Vapor Archive", description: "Neon gradients on deep purple." } }
      }.to change(Grimoire, :count).by(1)

      grimoire = Grimoire.last
      expect(response).to redirect_to(grimoire_path(grimoire))
      expect(grimoire.name).to eq("Vapor Archive")
    end

    it "returns to new project with the name preserved and the new grimoire selected" do
      expect {
        post grimoires_path, params: {
          grimoire: { name: "Vapor Archive", description: "Neon gradients on deep purple." },
          return_to_project: "1",
          project: { name: "My Talk" }
        }
      }.to change(Grimoire, :count).by(1)

      grimoire = Grimoire.last
      expect(response).to redirect_to(new_project_path(project: { name: "My Talk" }, source_grimoire_id: grimoire.id))
    end

    it "re-renders form on validation error" do
      post grimoires_path, params: { grimoire: { name: "", description: "No name" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /grimoires/:id" do
    it "shows the grimoire with full description" do
      grimoire = create(:grimoire, name: "Pirate Broadcast", description: "VHS static. Full description here.")

      get grimoire_path(grimoire)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pirate Broadcast")
      expect(response.body).to include("VHS static. Full description here.")
    end
  end

  describe "GET /grimoires/:id/edit" do
    it "renders the edit form" do
      grimoire = create(:grimoire)

      get edit_grimoire_path(grimoire)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(grimoire.name)
    end
  end

  describe "PATCH /grimoires/:id" do
    it "updates the grimoire" do
      grimoire = create(:grimoire, name: "Old Name")

      patch grimoire_path(grimoire), params: { grimoire: { name: "New Name" } }
      expect(response).to redirect_to(grimoire_path(grimoire))
      expect(grimoire.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /grimoires/:id" do
    it "deletes the grimoire and redirects to index" do
      grimoire = create(:grimoire)

      expect {
        delete grimoire_path(grimoire)
      }.to change(Grimoire, :count).by(-1)

      expect(response).to redirect_to(grimoires_path)
    end
  end
end
