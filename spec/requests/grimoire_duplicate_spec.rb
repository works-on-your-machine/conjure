require "rails_helper"

RSpec.describe "Grimoire Duplicate", type: :request do
  describe "POST /grimoires/:id/duplicate" do
    it "creates a copy with '(copy)' appended to name" do
      grimoire = create(:grimoire, name: "Pirate Broadcast", description: "VHS static.")

      expect {
        post duplicate_grimoire_path(grimoire)
      }.to change(Grimoire, :count).by(1)

      copy = Grimoire.last
      expect(copy.name).to eq("Pirate Broadcast (copy)")
      expect(copy.description).to eq("VHS static.")
    end

    it "redirects to the edit page of the copy" do
      grimoire = create(:grimoire)

      post duplicate_grimoire_path(grimoire)
      copy = Grimoire.last
      expect(response).to redirect_to(edit_grimoire_path(copy))
    end

    it "creates an independent copy" do
      grimoire = create(:grimoire, name: "Original", description: "Original desc")

      post duplicate_grimoire_path(grimoire)
      copy = Grimoire.last

      copy.update!(description: "Modified desc")
      expect(grimoire.reload.description).to eq("Original desc")
    end
  end
end
