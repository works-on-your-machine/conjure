require "rails_helper"

RSpec.describe Grimoire, type: :model do
  describe "validations" do
    it "requires a name" do
      grimoire = build(:grimoire, name: nil)
      expect(grimoire).not_to be_valid
      expect(grimoire.errors[:name]).to include("can't be blank")
    end

    it "is valid with a name and description" do
      grimoire = build(:grimoire)
      expect(grimoire).to be_valid
    end
  end

  describe "associations" do
    it "has many projects" do
      grimoire = create(:grimoire)
      project = create(:project, grimoire: grimoire)
      expect(grimoire.projects).to include(project)
    end
  end

  describe "counter cache" do
    it "tracks projects_count" do
      grimoire = create(:grimoire)
      expect(grimoire.projects_count).to eq(0)

      create(:project, grimoire: grimoire)
      grimoire.reload
      expect(grimoire.projects_count).to eq(1)

      create(:project, grimoire: grimoire, name: "Another Deck")
      grimoire.reload
      expect(grimoire.projects_count).to eq(2)
    end

    it "decrements when a project is destroyed" do
      grimoire = create(:grimoire)
      project = create(:project, grimoire: grimoire)
      grimoire.reload
      expect(grimoire.projects_count).to eq(1)

      project.destroy
      grimoire.reload
      expect(grimoire.projects_count).to eq(0)
    end
  end
end
