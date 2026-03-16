require "rails_helper"

RSpec.describe "Application Layout", type: :request do
  describe "GET /" do
    it "renders with the Conjure header and navigation" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Conjure")
      expect(response.body).to include("Grimoire library")
      expect(response.body).to include("Settings")
    end

    it "includes Google Fonts" do
      get root_path
      expect(response.body).to include("fonts.googleapis.com")
      expect(response.body).to include("Cormorant+Garamond")
      expect(response.body).to include("DM+Sans")
    end

    it "uses the dark theme background" do
      get root_path
      expect(response.body).to include("bg-plum")
    end
  end
end

RSpec.describe "Project Layout", type: :request do
  let!(:project) { create(:project) }

  describe "GET /projects/:id" do
    it "renders the four-section sidebar" do
      get project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Grimoire")
      expect(response.body).to include("Incantations")
      expect(response.body).to include("Visions")
      expect(response.body).to include("Final cut")
    end

    it "shows the back to workshop link" do
      get project_path(project)
      expect(response.body).to include("Workshop")
    end

    it "shows the project name" do
      get project_path(project)
      expect(response.body).to include(project.name)
    end

    it "shows the grimoire name" do
      get project_path(project)
      expect(response.body).to include(project.grimoire.name)
    end
  end
end
