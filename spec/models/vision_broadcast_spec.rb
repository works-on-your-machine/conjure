require "rails_helper"

RSpec.describe "Vision broadcasts", type: :model do
  let(:project) { create(:project) }
  let(:slide) { create(:slide, project: project) }
  let(:conjuring) { create(:conjuring, project: project, status: :generating) }

  describe "after vision completes" do
    it "broadcasts a turbo stream append to the project channel" do
      vision = create(:vision, slide: slide, conjuring: conjuring, status: :pending)

      expect {
        vision.complete!
      }.to have_broadcasted_to("project_#{project.id}_visions").from_channel(Turbo::StreamsChannel)
    end
  end

  describe "after conjuring status changes" do
    it "broadcasts a turbo stream to the project channel" do
      expect {
        conjuring.complete!
      }.to have_broadcasted_to("project_#{project.id}_conjuring").from_channel(Turbo::StreamsChannel)
    end
  end
end
