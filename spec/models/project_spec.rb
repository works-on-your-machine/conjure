require "rails_helper"

RSpec.describe Project, type: :model do
  describe "validations" do
    it "requires a name" do
      project = build(:project, name: nil)
      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("can't be blank")
    end

    it "requires a grimoire" do
      project = build(:project, grimoire: nil)
      expect(project).not_to be_valid
    end

    it "is valid with a name and grimoire" do
      project = build(:project)
      expect(project).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a grimoire" do
      project = create(:project)
      expect(project.grimoire).to be_a(Grimoire)
    end
  end

  describe "defaults" do
    it "defaults aspect_ratio to 16:9" do
      project = create(:project)
      expect(project.aspect_ratio).to eq("16:9")
    end

    it "defaults default_variations to 5" do
      project = create(:project)
      expect(project.default_variations).to eq(5)
    end
  end
end
