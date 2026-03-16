require "rails_helper"

RSpec.describe "Settings Storage", type: :request do
  describe "GET /settings" do
    it "shows vision count" do
      get settings_path
      expect(response.body).to include("0 visions")
    end

    it "shows vision count when visions exist" do
      project = create(:project)
      conjuring = create(:conjuring, project: project)
      slide = create(:slide, project: project)
      create(:vision, conjuring: conjuring, slide: slide)
      create(:vision, conjuring: conjuring, slide: slide, position: 2)

      get settings_path
      expect(response.body).to include("2 visions")
    end
  end

  describe "DELETE /settings/clear_unselected" do
    it "deletes all unselected visions" do
      project = create(:project)
      conjuring = create(:conjuring, project: project)
      slide = create(:slide, project: project)
      create(:vision, conjuring: conjuring, slide: slide, selected: false, position: 1)
      create(:vision, conjuring: conjuring, slide: slide, selected: false, position: 2)
      create(:vision, conjuring: conjuring, slide: slide, selected: true, position: 3)

      expect {
        delete clear_unselected_settings_path
      }.to change(Vision, :count).from(3).to(1)

      expect(response).to redirect_to(settings_path)
      expect(Vision.first.selected).to be true
    end

    it "does nothing when all visions are selected" do
      project = create(:project)
      conjuring = create(:conjuring, project: project)
      slide = create(:slide, project: project)
      create(:vision, conjuring: conjuring, slide: slide, selected: true)

      expect {
        delete clear_unselected_settings_path
      }.not_to change(Vision, :count)
    end
  end
end
