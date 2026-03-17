require "rails_helper"

RSpec.describe Project, type: :model do
  describe "validations" do
    it "requires a name" do
      project = build(:project, name: nil)
      expect(project).not_to be_valid
      expect(project.errors[:name]).to include("can't be blank")
    end

    it "requires a source grimoire" do
      project = build(:project, source_grimoire: nil)
      expect(project).not_to be_valid
    end

    it "is valid with a name and source grimoire" do
      project = build(:project)
      expect(project).to be_valid
    end
  end

  describe "associations" do
    it "copies the source grimoire into a project-local grimoire" do
      project = create(:project)
      expect(project.grimoire).to be_a(Grimoire)
      expect(project.grimoire).not_to eq(project.source_grimoire)
      expect(project.grimoire.name).to eq(project.source_grimoire.name)
      expect(project.grimoire.description).to eq(project.source_grimoire.description)
    end

    it "belongs to a source grimoire" do
      project = create(:project)
      expect(project.source_grimoire).to be_a(Grimoire)
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

  describe "destroy" do
    it "removes the project-local grimoire copy and preserves the source grimoire" do
      project = create(:project)
      project_grimoire_id = project.grimoire_id
      source_grimoire_id = project.source_grimoire_id

      project.destroy

      expect(Grimoire.exists?(project_grimoire_id)).to be(false)
      expect(Grimoire.exists?(source_grimoire_id)).to be(true)
    end
  end
end
