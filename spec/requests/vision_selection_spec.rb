require "rails_helper"

RSpec.describe "Vision Selection", type: :request do
  let!(:project) { create(:project) }
  let!(:slide) { create(:slide, project: project) }
  let!(:conjuring) { create(:conjuring, project: project) }

  describe "PATCH /projects/:project_id/visions/:id" do
    it "toggles a vision to selected" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: false)

      patch project_vision_path(project, vision), params: { vision: { selected: true } }
      expect(response).to redirect_to(project_path(project, section: "visions"))
      expect(vision.reload.selected).to be true
    end

    it "toggles a vision to unselected" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: true)

      patch project_vision_path(project, vision), params: { vision: { selected: false } }
      expect(vision.reload.selected).to be false
    end
  end
end
