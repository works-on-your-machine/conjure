require "rails_helper"

RSpec.describe "Slides (Incantations)", type: :request do
  let!(:project) { create(:project) }

  describe "GET /projects/:id?section=incantations" do
    it "shows the incantations section with slide list" do
      create(:slide, project: project, title: "Title card", position: 1)
      create(:slide, project: project, title: "The problem", position: 2)

      get incantations_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Incantations")
      expect(response.body).to include("Title card")
      expect(response.body).to include("The problem")
    end

    it "shows slide count" do
      create(:slide, project: project, position: 1)
      create(:slide, project: project, title: "Second", position: 2)

      get incantations_project_path(project)
      expect(response.body).to include("2 slides")
    end

    it "shows vision count badge for slides with visions" do
      slide = create(:slide, project: project, position: 1)
      conjuring = create(:conjuring, project: project)
      create(:vision, slide: slide, conjuring: conjuring)

      get incantations_project_path(project)
      # The badge should show "1" for the vision count
      expect(response.body).to match(/<span[^>]*>1<\/span>/)
    end
  end

  describe "GET /projects/:project_id/slides/:id/edit" do
    it "renders the slide editor" do
      slide = create(:slide, project: project, title: "My Slide", description: "Slide content")

      get edit_project_slide_path(project, slide)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Slide")
      expect(response.body).to include("Slide content")
    end

    it "shows the conjure vision button" do
      slide = create(:slide, project: project)

      get edit_project_slide_path(project, slide)
      expect(response.body).to include("Conjure vision")
    end

    it "shows generated visions" do
      slide = create(:slide, project: project)
      conjuring = create(:conjuring, project: project)
      vision = create(:vision, slide: slide, conjuring: conjuring, status: :complete)
      vision.image.attach(io: StringIO.new("fake"), filename: "test.png", content_type: "image/png")

      get edit_project_slide_path(project, slide)
      expect(response.body).to include("Generated visions (1)")
    end
  end

  describe "POST /projects/:project_id/slides" do
    it "creates a new slide at the end" do
      create(:slide, project: project, position: 1)

      expect {
        post project_slides_path(project), params: { slide: { title: "New Slide" } }
      }.to change(project.slides, :count).by(1)

      slide = project.slides.last
      expect(slide.title).to eq("New Slide")
      expect(slide.position).to eq(2)
    end
  end

  describe "PATCH /projects/:project_id/slides/:id" do
    it "updates the slide" do
      slide = create(:slide, project: project, title: "Old Title", description: "Old desc")

      patch project_slide_path(project, slide), params: { slide: { title: "New Title", description: "New desc" } }
      slide.reload
      expect(slide.title).to eq("New Title")
      expect(slide.description).to eq("New desc")
    end
  end

  describe "DELETE /projects/:project_id/slides/:id" do
    it "deletes the slide" do
      slide = create(:slide, project: project)

      expect {
        delete project_slide_path(project, slide)
      }.to change(project.slides, :count).by(-1)
    end
  end

  describe "PATCH /projects/:project_id/slides/:id/move" do
    it "moves a slide up" do
      slide1 = create(:slide, project: project, title: "First", position: 1)
      slide2 = create(:slide, project: project, title: "Second", position: 2)

      patch move_project_slide_path(project, slide2), params: { direction: "up" }

      expect(slide1.reload.position).to eq(2)
      expect(slide2.reload.position).to eq(1)
    end

    it "moves a slide down" do
      slide1 = create(:slide, project: project, title: "First", position: 1)
      slide2 = create(:slide, project: project, title: "Second", position: 2)

      patch move_project_slide_path(project, slide1), params: { direction: "down" }

      expect(slide1.reload.position).to eq(2)
      expect(slide2.reload.position).to eq(1)
    end
  end
end
