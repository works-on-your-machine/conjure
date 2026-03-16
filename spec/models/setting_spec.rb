require "rails_helper"

RSpec.describe Setting, type: :model do
  describe ".current" do
    it "returns the singleton setting record" do
      setting = Setting.current
      expect(setting).to be_a(Setting)
      expect(setting).to be_persisted
    end

    it "always returns the same record" do
      first = Setting.current
      second = Setting.current
      expect(first.id).to eq(second.id)
    end
  end

  describe "defaults" do
    it "defaults default_variations to 5" do
      setting = Setting.current
      expect(setting.default_variations).to eq(5)
    end

    it "defaults default_aspect_ratio to 16:9" do
      setting = Setting.current
      expect(setting.default_aspect_ratio).to eq("16:9")
    end
  end

  describe "API key storage" do
    it "stores and retrieves nano_banana_api_key" do
      setting = Setting.current
      setting.update!(nano_banana_api_key: "nb-test-key-123")
      setting.reload
      expect(setting.nano_banana_api_key).to eq("nb-test-key-123")
    end

    it "stores and retrieves llm_api_key" do
      setting = Setting.current
      setting.update!(llm_api_key: "sk-test-key-456")
      setting.reload
      expect(setting.llm_api_key).to eq("sk-test-key-456")
    end

    it "allows nil API keys" do
      setting = Setting.current
      expect(setting.nano_banana_api_key).to be_nil
      expect(setting.llm_api_key).to be_nil
    end
  end
end
