require "rails_helper"

RSpec.describe "Visions Wall", type: :request do
  let!(:project) { create(:project) }
  let!(:slide1) { create(:slide, project: project, title: "Title card", position: 1) }
  let!(:slide2) { create(:slide, project: project, title: "The problem", position: 2) }

  describe "GET /projects/:id?section=visions" do
    it "renders the visions section" do
      get project_path(project, section: "visions")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visions")
    end

    it "shows empty state when slides have no visions" do
      get project_path(project, section: "visions")
      expect(response.body).to include("No visions yet")
    end

    it "shows each slide as a labeled row when visions exist" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete)
      create(:vision, slide: slide2, conjuring: conjuring, position: 1, status: :complete)

      get project_path(project, section: "visions")
      expect(response.body).to include("Title card")
      expect(response.body).to include("The problem")
    end

    it "shows vision thumbnails for each slide" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete)
      create(:vision, slide: slide1, conjuring: conjuring, position: 2, status: :complete)

      get project_path(project, section: "visions")
      expect(response.body).to include("vision_")
    end

    it "shows conjuring badge on visions" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete)

      get project_path(project, section: "visions")
      expect(response.body).to include("Run 1")
    end

    it "shows selection count" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete, selected: true)

      get project_path(project, section: "visions")
      expect(response.body).to include("1/2 selected")
    end
  end

  describe "POST /projects/:project_id/conjurings" do
    before do
      Setting.current.update!(llm_api_key: "test-key")
      allow_any_instance_of(PromptAssemblyService).to receive(:assemble).and_return("prompt")
    end

    it "creates a conjuring with frozen grimoire_text and enqueues ConjuringJob" do
      expect {
        post project_conjurings_path(project), params: { conjuring: { scope: "all" } }
      }.to change(Conjuring, :count).by(1)

      conjuring = Conjuring.last
      expect(conjuring.grimoire_text).to eq(project.grimoire.description)
      expect(conjuring.variations_count).to eq(project.default_variations)
      expect(conjuring).to be_pending
      expect(response).to redirect_to(project_path(project, section: "visions"))
    end

    it "enqueues a ConjuringJob" do
      post project_conjurings_path(project), params: { conjuring: { scope: "all" } }
      expect(ConjuringJob).to have_been_enqueued
    end
  end
end
