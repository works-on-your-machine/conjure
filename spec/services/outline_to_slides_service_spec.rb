require "rails_helper"

RSpec.describe OutlineToSlidesService do
  let(:api_key) { "test-llm-key" }
  let(:service) { described_class.new(api_key: api_key) }
  let(:gemini_endpoint) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent" }

  let(:llm_response) do
    {
      candidates: [ {
        content: {
          parts: [ {
            text: '[{"title":"The problem","description":"Show the core tension"},{"title":"The solution","description":"The reveal moment"}]'
          } ]
        }
      } ]
    }.to_json
  end

  describe "#generate" do
    it "returns slides from LLM response" do
      stub_request(:post, gemini_endpoint)
        .with(query: { key: api_key })
        .to_return(status: 200, body: llm_response, headers: { "Content-Type" => "application/json" })

      slides = service.generate("Talk about the problem, then reveal the solution")

      expect(slides.length).to eq(2)
      expect(slides[0][:title]).to eq("The problem")
      expect(slides[1][:title]).to eq("The solution")
    end

    it "falls back to line-by-line parsing when LLM fails" do
      stub_request(:post, gemini_endpoint)
        .with(query: { key: api_key })
        .to_return(status: 500, body: '{"error":"fail"}')

      slides = service.generate("Open with the hook\nShow the data\nCall to action")

      expect(slides.length).to eq(3)
      expect(slides[0][:description]).to include("Open with the hook")
    end

    it "falls back when no API key" do
      service_no_key = described_class.new(api_key: nil)

      slides = service_no_key.generate("- First point\n- Second point")

      expect(slides.length).to eq(2)
    end
  end
end
