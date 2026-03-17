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

    it "uses the project form to branch into grimoire creation" do
      get new_project_path

      document = Nokogiri::HTML.parse(response.body)
      create_grimoire_button = document.at_css('button[name="return_to_project"][value="1"]')

      expect(create_grimoire_button["formaction"]).to eq(new_grimoire_path)
      expect(create_grimoire_button["formmethod"]).to eq("get")
    end

    it "prefills the project name and selected grimoire from return params" do
      get new_project_path, params: { project: { name: "My Talk" }, source_grimoire_id: grimoire.id }

      document = Nokogiri::HTML.parse(response.body)
      name_input = document.at_css('input[name="project[name]"]')
      selected_grimoire = document.at_css("input[name='project[source_grimoire_id]'][value='#{grimoire.id}']")

      expect(name_input["value"]).to eq("My Talk")
      expect(selected_grimoire["checked"]).to eq("checked")
    end
  end

  describe "POST /projects" do
    it "creates a project and redirects to workspace" do
      expect {
        post projects_path, params: { project: { name: "My Talk", source_grimoire_id: grimoire.id } }
      }.to change(Project, :count).by(1)

      project = Project.last
      expect(project.name).to eq("My Talk")
      expect(project.source_grimoire).to eq(grimoire)
      expect(project.grimoire).not_to eq(grimoire)
      expect(project.grimoire.name).to eq(grimoire.name)
      expect(project.grimoire.description).to eq(grimoire.description)
      expect(response).to redirect_to(grimoire_project_path(project))
    end

    it "fails without a name" do
      post projects_path, params: { project: { name: "", source_grimoire_id: grimoire.id } }
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
