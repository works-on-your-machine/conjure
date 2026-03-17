require "rails_helper"

RSpec.describe "Workshop (Home Screen)", type: :request do
  describe "GET /" do
    context "with projects" do
      it "shows project cards" do
        project = create(:project, name: "RubyConf Keynote")
        create(:slide, project: project, position: 1)
        create(:slide, project: project, position: 2)

        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("RubyConf Keynote")
      end

      it "shows grimoire name on each card" do
        grimoire = create(:grimoire, name: "Pirate Broadcast")
        create(:project, source_grimoire: grimoire)

        get root_path
        expect(response.body).to include("Pirate Broadcast")
      end

      it "shows slide count on each card" do
        project = create(:project)
        create(:slide, project: project, position: 1)
        create(:slide, project: project, position: 2)
        create(:slide, project: project, position: 3)

        get root_path
        expect(response.body).to include("3 slides")
      end

      it "shows the Conjure new project button" do
        create(:project)

        get root_path
        expect(response.body).to include("Conjure new project")
      end

      it "links cards to the project workspace" do
        project = create(:project)

        get root_path
        expect(response.body).to include(project_path(project))
      end
    end

    context "without projects" do
      it "shows the empty state" do
        get root_path
        expect(response.body).to include("Your workshop is empty")
        expect(response.body).to include("Every presentation begins as a vision")
      end

      it "shows the Start from scratch button" do
        get root_path
        expect(response.body).to include("Start from scratch")
        expect(response.body).to include(new_project_path)
      end

      it "does not show the project grid" do
        get root_path
        expect(response.body).not_to include("project_card")
      end
    end
  end
end
