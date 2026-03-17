require "rails_helper"

RSpec.describe "Visions Wall", type: :request do
  let!(:project) { create(:project) }
  let!(:slide1) { create(:slide, project: project, title: "Title card", position: 1) }
  let!(:slide2) { create(:slide, project: project, title: "The problem", position: 2) }

  describe "GET /projects/:id?section=visions" do
    it "renders the visions section" do
      get visions_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visions")
    end

    it "shows empty state when slides have no visions" do
      get visions_project_path(project)
      expect(response.body).to include("No visions yet")
    end

    it "shows each slide as a labeled row when visions exist" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete)
      create(:vision, slide: slide2, conjuring: conjuring, position: 1, status: :complete)

      get visions_project_path(project)
      expect(response.body).to include("Title card")
      expect(response.body).to include("The problem")
    end

    it "renders slide panel identifiers so row state can persist on the visions page" do
      get visions_project_path(project)

      expect(response.body).to include(%(data-slide-panel-project-id-value="#{project.id}"))
      expect(response.body).to include(%(data-slide-panel-slide-id-value="#{slide1.id}"))
      expect(response.body).to include(%(data-slide-panel-slide-id-value="#{slide2.id}"))
    end

    it "shows vision thumbnails for each slide" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete)
      create(:vision, slide: slide1, conjuring: conjuring, position: 2, status: :complete)

      get visions_project_path(project)
      expect(response.body).to include("vision_")
    end

    it "shows thumbnail rows instead of the browse placeholder when nothing is selected" do
      conjuring = create(:conjuring, project: project)
      vision_one = create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete)
      vision_two = create(:vision, slide: slide1, conjuring: conjuring, position: 2, status: :complete)

      get visions_project_path(project)
      expect(response.body).to include("vision_#{vision_one.id}")
      expect(response.body).to include("vision_#{vision_two.id}")
      expect(response.body).not_to include("click to browse")
    end

    it "shows conjuring badge on visions" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete)

      get visions_project_path(project)
      expect(response.body).to include("Run 1")
    end

    it "shows selection count" do
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide1, conjuring: conjuring, position: 1, status: :complete, selected: true)

      get visions_project_path(project)
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
      expect(response).to redirect_to(visions_project_path(project))
    end

    it "enqueues a ConjuringJob" do
      post project_conjurings_path(project), params: { conjuring: { scope: "all" } }
      expect(ConjuringJob).to have_been_enqueued
    end
  end
end
