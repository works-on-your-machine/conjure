require "rails_helper"

RSpec.describe ProjectExportService do
  let(:project) { create(:project, name: "My Presentation") }
  let(:slide) { create(:slide, project: project, title: "Title card", position: 1, description: "Dramatic title") }
  let(:conjuring) { create(:conjuring, project: project, grimoire_text: "VHS theme") }

  describe "#generate" do
    it "returns a zip with grimoire, slides, and conjuring metadata" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: true, position: 1,
        slide_text: "Dramatic title", prompt: "A VHS title card", status: :complete)
      vision.image.attach(io: StringIO.new("fake-png-data"), filename: "test.png", content_type: "image/png")

      service = described_class.new(project)
      zip_data = service.generate

      expect(zip_data).to be_present

      entries = []
      Zip::InputStream.open(StringIO.new(zip_data)) do |io|
        while entry = io.get_next_entry
          entries << entry.name
        end
      end

      expect(entries).to include("my-presentation/grimoire.txt")
      expect(entries).to include("my-presentation/slides/01-title-card.txt")
      expect(entries.any? { |e| e.include?("conjurings/") && e.end_with?("metadata.json") }).to be true
    end
  end
end
