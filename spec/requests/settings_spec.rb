require "rails_helper"

RSpec.describe "Settings", type: :request do
  describe "GET /settings" do
    it "renders the settings page" do
      get settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Settings")
    end

    it "shows default variations and aspect ratio" do
      get settings_path
      expect(response.body).to include("5")
      expect(response.body).to include("16:9")
    end

    it "shows empty fields when no API keys are set" do
      get settings_path
      expect(response.body).to include("Nano Banana 2 API key")
      expect(response.body).to include("LLM API key")
    end

    it "shows masked API keys when they are set" do
      setting = Setting.current
      setting.update!(nano_banana_api_key: "nb-secret-key-12345")
      setting.update!(llm_api_key: "sk-another-secret-key-67890")

      get settings_path
      # Should show masked version, not the full key
      expect(response.body).not_to include("nb-secret-key-12345")
      expect(response.body).not_to include("sk-another-secret-key-67890")
      expect(response.body).to include("•••")
    end
  end

  describe "PATCH /settings" do
    it "updates default variations and aspect ratio" do
      patch settings_path, params: { setting: { default_variations: 8, default_aspect_ratio: "4:3" } }
      expect(response).to redirect_to(settings_path)

      setting = Setting.current.reload
      expect(setting.default_variations).to eq(8)
      expect(setting.default_aspect_ratio).to eq("4:3")
    end

    it "updates API keys when provided" do
      patch settings_path, params: { setting: { nano_banana_api_key: "nb-new-key", llm_api_key: "sk-new-key" } }
      expect(response).to redirect_to(settings_path)

      setting = Setting.current.reload
      expect(setting.nano_banana_api_key).to eq("nb-new-key")
      expect(setting.llm_api_key).to eq("sk-new-key")
    end

    it "does not overwrite existing API key when field is blank" do
      Setting.current.update!(nano_banana_api_key: "nb-existing-key")

      patch settings_path, params: { setting: { nano_banana_api_key: "", default_variations: 10 } }
      expect(response).to redirect_to(settings_path)

      setting = Setting.current.reload
      expect(setting.nano_banana_api_key).to eq("nb-existing-key")
      expect(setting.default_variations).to eq(10)
    end

    it "sets a flash notice on success" do
      patch settings_path, params: { setting: { default_variations: 3 } }
      expect(flash[:notice]).to be_present
    end
  end
end
