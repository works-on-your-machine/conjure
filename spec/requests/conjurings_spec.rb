require "rails_helper"

RSpec.describe "Conjurings", type: :request do
  let!(:project) { create(:project) }
  let!(:slide) { create(:slide, project: project, position: 1) }

  before do
    allow(ConjuringJob).to receive(:perform_later)
  end

  describe "POST /projects/:project_id/conjurings" do
    it "creates a conjuring for all slides by default" do
      expect {
        post project_conjurings_path(project), params: { scope: "all", variations: 3 }
      }.to change(Conjuring, :count).by(1)

      expect(ConjuringJob).to have_received(:perform_later).with(Conjuring.last)
      expect(response).to redirect_to(visions_project_path(project))
    end

    it "creates a conjuring with single scope for one slide" do
      expect {
        post project_conjurings_path(project), params: { scope: "single", slide_id: slide.id, variations: 1 }
      }.to change(Conjuring, :count).by(1)

      conjuring = Conjuring.last
      expect(conjuring.variations_count).to eq(1)
      expect(ConjuringJob).to have_received(:perform_later).with(conjuring, slide_ids: [slide.id])
    end

    it "redirects to incantations when redirect_to param is set" do
      post project_conjurings_path(project), params: {
        scope: "single", slide_id: slide.id, variations: 1, redirect_to: "incantations"
      }

      expect(response).to redirect_to(incantations_project_path(project))
    end

    it "redirects to visions by default" do
      post project_conjurings_path(project), params: { scope: "all", variations: 3 }

      expect(response).to redirect_to(visions_project_path(project))
    end
  end
end
