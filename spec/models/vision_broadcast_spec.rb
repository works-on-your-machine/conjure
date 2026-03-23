require "rails_helper"

RSpec.describe "Vision broadcasts", type: :model do
  let(:project) { create(:project) }
  let(:slide) { create(:slide, project: project) }
  let(:conjuring) { create(:conjuring, project: project, status: :generating) }

  describe "after vision completes" do
    it "broadcasts a tile replacement to the project stream" do
      vision = create(:vision, slide: slide, conjuring: conjuring, status: :pending)

      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        project,
        target: "vision_tile_#{vision.id}",
        partial: "visions/vision_tile",
        locals: hash_including(vision: vision, project: project)
      )

      vision.complete!
    end
  end
end
