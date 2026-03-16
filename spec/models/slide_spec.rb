require "rails_helper"

RSpec.describe Slide, type: :model do
  describe "validations" do
    it "requires a title" do
      slide = build(:slide, title: nil)
      expect(slide).not_to be_valid
      expect(slide.errors[:title]).to include("can't be blank")
    end

    it "requires a position" do
      slide = build(:slide, position: nil)
      expect(slide).not_to be_valid
      expect(slide.errors[:position]).to include("can't be blank")
    end

    it "requires a project" do
      slide = build(:slide, project: nil)
      expect(slide).not_to be_valid
    end

    it "is valid with a title, position, and project" do
      slide = build(:slide)
      expect(slide).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a project" do
      slide = create(:slide)
      expect(slide.project).to be_a(Project)
    end
  end

  describe "ordering" do
    it "project.slides returns slides ordered by position" do
      project = create(:project)
      slide3 = create(:slide, project: project, position: 3, title: "Third")
      slide1 = create(:slide, project: project, position: 1, title: "First")
      slide2 = create(:slide, project: project, position: 2, title: "Second")

      expect(project.slides.pluck(:title)).to eq(%w[First Second Third])
    end
  end

  describe "dependent destroy" do
    it "is destroyed when its project is destroyed" do
      project = create(:project)
      create(:slide, project: project)
      expect { project.destroy }.to change(Slide, :count).by(-1)
    end
  end
end
