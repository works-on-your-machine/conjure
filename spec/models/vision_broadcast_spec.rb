require "rails_helper"

RSpec.describe "Vision broadcasts", type: :model do
  let(:project) { create(:project) }
  let(:slide) { create(:slide, project: project) }
  let(:conjuring) { create(:conjuring, project: project, status: :generating) }

  describe "after vision completes" do
    it "broadcasts updates to visions page and incantations page" do
      vision = create(:vision, slide: slide, conjuring: conjuring, status: :pending)

      # Vision tile replacement (visions page)
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        project,
        target: "vision_tile_#{vision.id}",
        partial: "visions/vision_tile",
        locals: hash_including(vision: vision, project: project)
      )

      # Slide editor replacement (incantations page)
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        project,
        target: "slide_editor",
        partial: "slides/edit",
        locals: hash_including(slide: slide, project: project)
      )

      vision.complete!
    end
  end
end
