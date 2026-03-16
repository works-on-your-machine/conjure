require "rails_helper"

RSpec.describe Conjuring, type: :model do
  describe "validations" do
    it "requires a project" do
      conjuring = build(:conjuring, project: nil)
      expect(conjuring).not_to be_valid
    end

    it "requires grimoire_text" do
      conjuring = build(:conjuring, grimoire_text: nil)
      expect(conjuring).not_to be_valid
      expect(conjuring.errors[:grimoire_text]).to include("can't be blank")
    end

    it "requires variations_count" do
      conjuring = build(:conjuring, variations_count: nil)
      expect(conjuring).not_to be_valid
      expect(conjuring.errors[:variations_count]).to include("can't be blank")
    end

    it "is valid with all required attributes" do
      conjuring = build(:conjuring)
      expect(conjuring).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a project" do
      conjuring = create(:conjuring)
      expect(conjuring.project).to be_a(Project)
    end

    it "has many visions with dependent destroy" do
      conjuring = create(:conjuring)
      slide = create(:slide, project: conjuring.project)
      create(:vision, conjuring: conjuring, slide: slide)

      expect(conjuring.visions.count).to eq(1)
      expect { conjuring.destroy }.to change(Vision, :count).by(-1)
    end
  end

  describe "enum" do
    it "has status enum with pending, generating, complete, failed" do
      conjuring = create(:conjuring)

      expect(conjuring).to be_pending
      conjuring.generating!
      expect(conjuring).to be_generating
      conjuring.complete!
      expect(conjuring).to be_complete
      conjuring.failed!
      expect(conjuring).to be_failed
    end

    it "defaults to pending" do
      conjuring = create(:conjuring)
      expect(conjuring.status).to eq("pending")
    end
  end
end
