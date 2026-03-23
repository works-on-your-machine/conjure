require "rails_helper"

RSpec.describe "Vision broadcasts", type: :model do
  let(:project) { create(:project) }
  let(:slide) { create(:slide, project: project) }
  let(:conjuring) { create(:conjuring, project: project, status: :generating) }

  describe "after vision completes" do
    it "enqueues a refresh broadcast to the project stream" do
      vision = create(:vision, slide: slide, conjuring: conjuring, status: :pending)

      expect {
        vision.complete!
      }.to have_enqueued_job(Turbo::Streams::BroadcastStreamJob)
    end
  end

  describe "after conjuring status changes" do
    it "enqueues a refresh broadcast to the project stream" do
      expect {
        conjuring.complete!
      }.to have_enqueued_job(Turbo::Streams::BroadcastStreamJob)
    end
  end
end
