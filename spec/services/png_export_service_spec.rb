require "rails_helper"

RSpec.describe PngExportService do
  let(:project) { create(:project, name: "My Presentation") }
  let(:slide) { create(:slide, project: project, title: "Title card", position: 1) }
  let(:conjuring) { create(:conjuring, project: project) }

  describe "#generate" do
    it "returns a zip file as string data" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: true, position: 1, status: :complete)
      vision.image.attach(io: StringIO.new("fake-png-data"), filename: "test.png", content_type: "image/png")

      service = described_class.new(project)
      zip_data = service.generate

      expect(zip_data).to be_present

      # Verify it's a valid zip
      entries = []
      Zip::InputStream.open(StringIO.new(zip_data)) do |io|
        while entry = io.get_next_entry
          entries << entry.name
        end
      end
      expect(entries).to include("01-title-card.png")
    end
  end
end
