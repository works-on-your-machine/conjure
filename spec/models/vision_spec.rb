require "rails_helper"

RSpec.describe Vision, type: :model do
  describe "validations" do
    it "requires a slide" do
      vision = build(:vision, slide: nil)
      expect(vision).not_to be_valid
    end

    it "requires a conjuring" do
      vision = build(:vision, conjuring: nil)
      expect(vision).not_to be_valid
    end

    it "is valid with all required attributes" do
      vision = build(:vision)
      expect(vision).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a slide" do
      vision = create(:vision)
      expect(vision.slide).to be_a(Slide)
    end

    it "belongs to a conjuring" do
      vision = create(:vision)
      expect(vision.conjuring).to be_a(Conjuring)
    end

    it "has one attached image" do
      vision = create(:vision)
      expect(vision).to respond_to(:image)
      expect(vision.image).not_to be_attached
    end
  end

  describe "attributes" do
    it "stores slide_text as a frozen copy" do
      vision = create(:vision, slide_text: "Original description")
      expect(vision.slide_text).to eq("Original description")
    end

    it "stores the assembled prompt" do
      vision = create(:vision, prompt: "A VHS-style title card")
      expect(vision.prompt).to eq("A VHS-style title card")
    end

    it "stores optional refinement" do
      vision = create(:vision, refinement: nil)
      expect(vision.refinement).to be_nil

      vision.update!(refinement: "Make the headline bigger")
      expect(vision.refinement).to eq("Make the headline bigger")
    end

    it "defaults selected to false" do
      vision = create(:vision)
      expect(vision.selected).to be false
    end
  end

  describe "project association through conjuring" do
    it "is accessible through project.visions" do
      project = create(:project)
      conjuring = create(:conjuring, project: project)
      slide = create(:slide, project: project)
      vision = create(:vision, conjuring: conjuring, slide: slide)

      expect(project.visions).to include(vision)
    end
  end

  describe "dependent destroy chain" do
    it "is destroyed when its conjuring is destroyed" do
      conjuring = create(:conjuring)
      slide = create(:slide, project: conjuring.project)
      create(:vision, conjuring: conjuring, slide: slide)

      expect { conjuring.destroy }.to change(Vision, :count).by(-1)
    end

    it "is destroyed when its project is destroyed" do
      project = create(:project)
      conjuring = create(:conjuring, project: project)
      slide = create(:slide, project: project)
      create(:vision, conjuring: conjuring, slide: slide)

      expect { project.destroy }.to change(Vision, :count).by(-1)
    end
  end
end
