require "rails_helper"

RSpec.describe "Final Cut", type: :request do
  let!(:project) { create(:project) }
  let!(:slide1) { create(:slide, project: project, title: "Title card", position: 1) }
  let!(:slide2) { create(:slide, project: project, title: "The problem", position: 2) }
  let!(:slide3) { create(:slide, project: project, title: "Call to action", position: 3) }
  let!(:conjuring) { create(:conjuring, project: project) }

  describe "GET /projects/:id?section=assembly" do
    it "renders the Final Cut section" do
      get assembly_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Final cut")
    end

    it "shows selected visions in slide order" do
      create(:vision, slide: slide1, conjuring: conjuring, selected: true, position: 1, status: :complete)
      create(:vision, slide: slide2, conjuring: conjuring, selected: true, position: 1, status: :complete)

      get assembly_project_path(project)
      expect(response.body).to include("Title card")
      expect(response.body).to include("The problem")
    end

    it "shows dashed placeholder for slides without a selected vision" do
      get assembly_project_path(project)
      expect(response.body).to include("No vision")
    end

    it "shows selection count" do
      create(:vision, slide: slide1, conjuring: conjuring, selected: true, position: 1, status: :complete)

      get assembly_project_path(project)
      expect(response.body).to include("1/3")
    end

    it "shows Refine button on slides with selected visions" do
      create(:vision, slide: slide1, conjuring: conjuring, selected: true, position: 1, status: :complete)

      get assembly_project_path(project)
      expect(response.body).to include("Refine")
    end

    it "shows back to visions link" do
      get assembly_project_path(project)
      expect(response.body).to include("Visions")
    end

    it "shows the images zip export button" do
      get assembly_project_path(project)
      expect(response.body).to include("Export images zip")
    end
  end

  describe "POST /projects/:project_id/conjurings (refinement)" do
    before do
      Setting.current.update!(llm_api_key: "test-key")
      allow_any_instance_of(PromptAssemblyService).to receive(:assemble).and_return("refined prompt")
    end

    it "creates a refinement conjuring scoped to one slide" do
      expect {
        post project_conjurings_path(project), params: {
          conjuring: { scope: "refine", slide_id: slide1.id, refinement: "Make the headline bigger" }
        }
      }.to change(Conjuring, :count).by(1)

      conjuring = Conjuring.last
      expect(conjuring.variations_count).to eq(1)
      expect(response).to redirect_to(assembly_project_path(project))
    end
  end
end
