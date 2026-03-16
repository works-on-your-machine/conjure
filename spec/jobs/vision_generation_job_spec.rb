require "rails_helper"

RSpec.describe VisionGenerationJob, type: :job do
  let(:project) { create(:project) }
  let(:slide) { create(:slide, project: project) }
  let(:conjuring) { create(:conjuring, project: project) }
  let(:vision) { create(:vision, slide: slide, conjuring: conjuring, status: :pending, prompt: "A dramatic title card") }

  let(:image_result) { { image_data: Base64.strict_encode64("fake-png"), mime_type: "image/png" } }

  before do
    Setting.current.update!(nano_banana_api_key: "test-image-key")
  end

  describe "#perform" do
    it "generates an image and attaches it to the vision" do
      allow_any_instance_of(GeminiImageProvider).to receive(:generate).and_return(image_result)

      VisionGenerationJob.perform_now(vision)

      vision.reload
      expect(vision).to be_complete
      expect(vision.image).to be_attached
    end

    it "sets vision status to generating then complete" do
      allow_any_instance_of(GeminiImageProvider).to receive(:generate).and_return(image_result)

      VisionGenerationJob.perform_now(vision)
      expect(vision.reload).to be_complete
    end

    it "calls GeminiImageProvider with the vision's prompt and project aspect ratio" do
      provider = instance_double(GeminiImageProvider)
      allow(GeminiImageProvider).to receive(:new).and_return(provider)
      expect(provider).to receive(:generate).with(
        prompt: "A dramatic title card",
        aspect_ratio: project.aspect_ratio
      ).and_return(image_result)

      VisionGenerationJob.perform_now(vision)
    end

    it "marks vision as failed on ClientError (no retry)" do
      allow_any_instance_of(GeminiImageProvider).to receive(:generate)
        .and_raise(GeminiImageProvider::ClientError, "Bad request")

      VisionGenerationJob.perform_now(vision)
      expect(vision.reload).to be_failed
    end

    it "re-enqueues on RateLimitError for retry" do
      allow_any_instance_of(GeminiImageProvider).to receive(:generate)
        .and_raise(GeminiImageProvider::RateLimitError, "Rate limited")

      expect {
        VisionGenerationJob.perform_now(vision)
      }.to have_enqueued_job(VisionGenerationJob)
    end

    it "re-enqueues on ServerError for retry" do
      allow_any_instance_of(GeminiImageProvider).to receive(:generate)
        .and_raise(GeminiImageProvider::ServerError, "Server error")

      expect {
        VisionGenerationJob.perform_now(vision)
      }.to have_enqueued_job(VisionGenerationJob)
    end
  end

  describe "conjuring completion" do
    it "marks conjuring complete when all visions are done" do
      allow_any_instance_of(GeminiImageProvider).to receive(:generate).and_return(image_result)

      create(:vision, slide: slide, conjuring: conjuring, status: :complete, position: 2)
      conjuring.update!(status: :generating)

      VisionGenerationJob.perform_now(vision)

      expect(conjuring.reload).to be_complete
    end

    it "marks conjuring failed when all visions failed" do
      allow_any_instance_of(GeminiImageProvider).to receive(:generate)
        .and_raise(GeminiImageProvider::ClientError, "Bad request")

      other_vision = create(:vision, slide: slide, conjuring: conjuring, status: :failed, position: 2)
      conjuring.update!(status: :generating)

      VisionGenerationJob.perform_now(vision)

      expect(conjuring.reload).to be_failed
    end
  end
end
