require "rails_helper"

RSpec.describe PdfExportService do
  let(:project) { create(:project, name: "My Presentation") }
  let(:slide1) { create(:slide, project: project, title: "Title card", position: 1) }
  let(:slide2) { create(:slide, project: project, title: "The problem", position: 2) }
  let(:conjuring) { create(:conjuring, project: project) }

  describe "#generate" do
    it "returns PDF data as a string" do
      v1 = create(:vision, slide: slide1, conjuring: conjuring, selected: true, status: :complete)
      v1.image.attach(io: StringIO.new(File.read(Rails.root.join("spec/fixtures/files/test_image.png"), mode: "rb")), filename: "test.png", content_type: "image/png")

      v2 = create(:vision, slide: slide2, conjuring: conjuring, selected: true, status: :complete)
      v2.image.attach(io: StringIO.new(File.read(Rails.root.join("spec/fixtures/files/test_image.png"), mode: "rb")), filename: "test2.png", content_type: "image/png")

      service = described_class.new(project)
      pdf_data = service.generate

      expect(pdf_data).to be_present
      expect(pdf_data[0..3]).to eq("%PDF")
    end

    it "sizes each page to the selected image dimensions" do
      image_data = File.binread(Rails.root.join("spec/fixtures/files/test_image.png"))
      image = Prawn.image_handler.find(image_data).new(image_data)
      v1 = create(:vision, slide: slide1, conjuring: conjuring, selected: true, status: :complete)
      v2 = create(:vision, slide: slide2, conjuring: conjuring, selected: true, status: :complete)

      v1.image.attach(io: StringIO.new(image_data), filename: "test.png", content_type: "image/png")
      v2.image.attach(io: StringIO.new(image_data), filename: "test2.png", content_type: "image/png")

      pdf_data = described_class.new(project).generate

      expect(pdf_data.scan("MediaBox [0 0 #{image.width} #{image.height}]").size).to eq(2)
    end

    it "returns nil when no selected visions exist" do
      service = described_class.new(project)
      expect(service.generate).to be_nil
    end
  end
end
