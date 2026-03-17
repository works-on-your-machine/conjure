require "rails_helper"

RSpec.describe "Vision Selection", type: :request do
  let!(:project) { create(:project) }
  let!(:slide) { create(:slide, project: project) }
  let!(:conjuring) { create(:conjuring, project: project) }

  describe "PATCH /projects/:project_id/visions/:id" do
    it "selects a vision" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: false)

      patch project_vision_path(project, vision), params: { vision: { selected: true } }
      expect(response).to redirect_to(visions_project_path(project))
      expect(vision.reload.selected).to be true
    end

    it "deselects a vision" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: true)

      patch project_vision_path(project, vision), params: { vision: { selected: false } }
      expect(vision.reload.selected).to be false
    end

    it "deselects other visions on the same slide when selecting" do
      old_selected = create(:vision, slide: slide, conjuring: conjuring, selected: true, position: 1)
      new_vision = create(:vision, slide: slide, conjuring: conjuring, selected: false, position: 2)

      patch project_vision_path(project, new_vision), params: { vision: { selected: true } }

      expect(new_vision.reload.selected).to be true
      expect(old_selected.reload.selected).to be false
    end

    it "does not affect visions on other slides" do
      other_slide = create(:slide, project: project, position: 2, title: "Other")
      other_vision = create(:vision, slide: other_slide, conjuring: conjuring, selected: true, position: 1)
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: false, position: 1)

      patch project_vision_path(project, vision), params: { vision: { selected: true } }

      expect(vision.reload.selected).to be true
      expect(other_vision.reload.selected).to be true
    end

    it "keeps the slide open and marks the clicked vision selected for turbo responses" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: false, position: 2)

      patch project_vision_path(project, vision),
        params: { vision: { selected: true }, open_slide: slide.id },
        as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(%(data-slide-panel-open-value="true"))
      expect(response.body).to include("v2 chosen")
    end
  end

  describe "DELETE /projects/:project_id/visions/:id (failed vision)" do
    it "deletes a failed vision" do
      vision = create(:vision, slide: slide, conjuring: conjuring, status: :failed)

      expect {
        delete project_vision_path(project, vision)
      }.to change(Vision, :count).by(-1)
    end
  end
end
