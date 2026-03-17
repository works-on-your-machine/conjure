require "rails_helper"

RSpec.describe "Vision Features", type: :request do
  let!(:project) { create(:project) }
  let!(:slide) { create(:slide, project: project) }
  let!(:conjuring) { create(:conjuring, project: project) }

  describe "GET /projects/:project_id/visions/:id (Provenance)" do
    it "shows the vision provenance details" do
      vision = create(:vision, slide: slide, conjuring: conjuring,
        slide_text: "Dramatic title", prompt: "A VHS-style title card",
        refinement: "Make it bigger", status: :complete)

      get project_vision_path(project, vision)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dramatic title")
      expect(response.body).to include("A VHS-style title card")
      expect(response.body).to include("Make it bigger")
      expect(response.body).to include(conjuring.grimoire_text)
    end
  end

  describe "DELETE /projects/:project_id/visions/:id" do
    it "deletes an individual vision" do
      vision = create(:vision, slide: slide, conjuring: conjuring)

      expect {
        delete project_vision_path(project, vision)
      }.to change(Vision, :count).by(-1)

      expect(response).to redirect_to(visions_project_path(project))
    end
  end

  describe "DELETE /projects/:project_id/conjurings/:id (Bulk delete)" do
    it "deletes all visions from a conjuring" do
      create(:vision, slide: slide, conjuring: conjuring, position: 1)
      create(:vision, slide: slide, conjuring: conjuring, position: 2)
      create(:vision, slide: slide, conjuring: conjuring, position: 3)

      expect {
        delete project_conjuring_path(project, conjuring)
      }.to change(Vision, :count).by(-3)

      expect(response).to redirect_to(visions_project_path(project))
    end
  end
end
