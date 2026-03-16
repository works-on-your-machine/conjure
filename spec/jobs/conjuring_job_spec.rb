require "rails_helper"

RSpec.describe ConjuringJob, type: :job do
  let(:project) { create(:project) }
  let!(:slide1) { create(:slide, project: project, position: 1, title: "Title card", description: "Dramatic title") }
  let!(:slide2) { create(:slide, project: project, position: 2, title: "The problem", description: "Breaking news frame") }
  let(:conjuring) { create(:conjuring, project: project, variations_count: 3, grimoire_text: "VHS static") }

  before do
    Setting.current.update!(llm_api_key: "test-llm-key")
    allow_any_instance_of(PromptAssemblyService).to receive(:assemble).and_return("assembled prompt")
  end

  describe "#perform" do
    it "sets conjuring status to generating then enqueues vision jobs" do
      ConjuringJob.perform_now(conjuring)
      # After perform_now, conjuring should still be generating (vision jobs haven't run yet)
      # unless there are 0 slides. With slides, it stays generating until VisionGenerationJobs complete.
      expect(conjuring.reload.status).to eq("generating")
    end

    it "creates vision records for each slide × variation" do
      expect {
        ConjuringJob.perform_now(conjuring)
      }.to change(Vision, :count).by(6) # 2 slides × 3 variations
    end

    it "creates visions with correct attributes" do
      ConjuringJob.perform_now(conjuring)

      visions = Vision.where(conjuring: conjuring, slide: slide1)
      expect(visions.count).to eq(3)
      expect(visions.pluck(:position)).to match_array([ 1, 2, 3 ])
      expect(visions.first.slide_text).to eq("Dramatic title")
      expect(visions.first.prompt).to eq("assembled prompt")
      expect(visions.first).to be_pending
    end

    it "enqueues VisionGenerationJob for each vision" do
      ConjuringJob.perform_now(conjuring)
      expect(VisionGenerationJob).to have_been_enqueued.exactly(6).times
    end

    it "freezes slide_text from current slide description" do
      ConjuringJob.perform_now(conjuring)

      vision = Vision.find_by(conjuring: conjuring, slide: slide1)
      expect(vision.slide_text).to eq("Dramatic title")

      # Even if slide description changes later, vision.slide_text is frozen
      slide1.update!(description: "Changed description")
      expect(vision.reload.slide_text).to eq("Dramatic title")
    end

    it "sets conjuring to failed if an error occurs during setup" do
      allow_any_instance_of(PromptAssemblyService).to receive(:assemble).and_raise(StandardError, "boom")

      ConjuringJob.perform_now(conjuring)
      expect(conjuring.reload.status).to eq("failed")
    end
  end
end
