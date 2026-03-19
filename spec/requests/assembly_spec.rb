require "rails_helper"

RSpec.describe "Assembly (Final Cut)", type: :request do
  let!(:project) { create(:project) }
  let!(:slide) { create(:slide, project: project, position: 1) }
  let!(:conjuring) { create(:conjuring, project: project) }

  describe "GET /projects/:id/assembly" do
    it "renders the assembly page" do
      get assembly_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Final cut")
    end

    it "shows selection count" do
      get assembly_project_path(project)
      expect(response.body).to include("0/1 slides selected")
    end

    it "shows thumbnail strip when multiple visions exist" do
      v1 = create(:vision, slide: slide, conjuring: conjuring, position: 1, status: :complete)
      v1.image.attach(io: StringIO.new("fake1"), filename: "v1.png", content_type: "image/png")
      v2 = create(:vision, slide: slide, conjuring: conjuring, position: 2, status: :complete)
      v2.image.attach(io: StringIO.new("fake2"), filename: "v2.png", content_type: "image/png")

      get assembly_project_path(project)
      # Both thumbnails should render as button_to forms with return_to=assembly
      expect(response.body).to include("return_to")
    end

    it "shows selected vision image" do
      v = create(:vision, slide: slide, conjuring: conjuring, position: 1, status: :complete, selected: true)
      v.image.attach(io: StringIO.new("fake"), filename: "v.png", content_type: "image/png")

      get assembly_project_path(project)
      expect(response.body).to include("1/1 slides selected")
    end
  end
end
