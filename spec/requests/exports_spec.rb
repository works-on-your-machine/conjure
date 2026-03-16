require "rails_helper"

RSpec.describe "Exports", type: :request do
  let!(:project) { create(:project, name: "My Talk") }
  let!(:slide) { create(:slide, project: project, title: "Title card", position: 1) }
  let!(:conjuring) { create(:conjuring, project: project) }

  describe "GET /projects/:project_id/export/pdf" do
    it "downloads a PDF when selected visions exist" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: true, status: :complete)
      vision.image.attach(
        io: StringIO.new(File.binread(Rails.root.join("spec/fixtures/files/test_image.png"))),
        filename: "test.png", content_type: "image/png"
      )

      get project_export_pdf_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("my-talk.pdf")
    end

    it "redirects when no selected visions" do
      get project_export_pdf_path(project)
      expect(response).to redirect_to(project_path(project, section: "assembly"))
    end
  end

  describe "GET /projects/:project_id/export/png" do
    it "downloads a zip of PNGs" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: true, status: :complete)
      vision.image.attach(io: StringIO.new("fake-png"), filename: "test.png", content_type: "image/png")

      get project_export_png_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("application/zip")
      expect(response.headers["Content-Disposition"]).to include("my-talk-slides.zip")
    end
  end

  describe "GET /projects/:project_id/export/project" do
    it "downloads a project zip" do
      vision = create(:vision, slide: slide, conjuring: conjuring, selected: true, status: :complete,
        slide_text: "Title", prompt: "A title card")
      vision.image.attach(io: StringIO.new("fake-png"), filename: "test.png", content_type: "image/png")

      get project_export_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("application/zip")
      expect(response.headers["Content-Disposition"]).to include("my-talk-project.zip")
    end
  end
end
