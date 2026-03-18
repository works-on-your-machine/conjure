require "rails_helper"

RSpec.describe PromptAssemblyService do
  let(:api_key) { "test-llm-key" }
  let(:service) { described_class.new(api_key: api_key) }
  let(:gemini_endpoint) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent" }

  let(:grimoire_text) { "VHS static. CRT monitors with scan lines. Punk zine meets late-night public access TV." }
  let(:slide_text) { "Talk title with dramatic presentation. The name of the talk in large type." }

  let(:llm_success_response) do
    {
      candidates: [
        {
          content: {
            parts: [
              { text: "A dramatic VHS-style title card with glowing phosphor green text on a black CRT monitor, scan lines visible, punk zine aesthetic with tape artifacts" }
            ]
          }
        }
      ]
    }.to_json
  end

  describe "#assemble" do
    it "returns a prompt string from the LLM" do
      stub_request(:post, gemini_endpoint)
        .with(query: { key: api_key })
        .to_return(status: 200, body: llm_success_response, headers: { "Content-Type" => "application/json" })

      result = service.assemble(grimoire_text: grimoire_text, slide_text: slide_text)

      expect(result).to be_a(String)
      expect(result).to include("VHS")
    end

    it "sends grimoire_text and slide_text to the LLM" do
      stub = stub_request(:post, gemini_endpoint)
        .with(
          query: { key: api_key },
          body: /VHS static.*Talk title/m
        )
        .to_return(status: 200, body: llm_success_response, headers: { "Content-Type" => "application/json" })

      service.assemble(grimoire_text: grimoire_text, slide_text: slide_text)
      expect(stub).to have_been_requested
    end

    it "includes refinement when provided" do
      stub = stub_request(:post, gemini_endpoint)
        .with(
          query: { key: api_key },
          body: /Make the headline bigger/
        )
        .to_return(status: 200, body: llm_success_response, headers: { "Content-Type" => "application/json" })

      service.assemble(grimoire_text: grimoire_text, slide_text: slide_text, refinement: "Make the headline bigger")
      expect(stub).to have_been_requested
    end

    it "falls back to concatenation when the LLM call fails" do
      stub_request(:post, gemini_endpoint)
        .with(query: { key: api_key })
        .to_return(status: 500, body: '{"error":{"message":"Server error"}}')

      result = service.assemble(grimoire_text: grimoire_text, slide_text: slide_text)

      expect(result).to include(grimoire_text)
      expect(result).to include(slide_text)
    end

    it "falls back to concatenation when api_key is blank" do
      service_no_key = described_class.new(api_key: nil)

      result = service_no_key.assemble(grimoire_text: grimoire_text, slide_text: slide_text)

      expect(result).to include(grimoire_text)
      expect(result).to include(slide_text)
    end

    it "includes refinement in fallback concatenation" do
      service_no_key = described_class.new(api_key: nil)

      result = service_no_key.assemble(
        grimoire_text: grimoire_text,
        slide_text: slide_text,
        refinement: "More grain texture"
      )

      expect(result).to include("More grain texture")
    end

    it "includes default slide design principles in the request" do
      stub = stub_request(:post, gemini_endpoint)
        .with(
          query: { key: api_key },
          body: /SLIDE DESIGN PRINCIPLES.*communicates one idea/m
        )
        .to_return(status: 200, body: llm_success_response, headers: { "Content-Type" => "application/json" })

      service.assemble(grimoire_text: grimoire_text, slide_text: slide_text)
      expect(stub).to have_been_requested
    end

    it "uses a custom slide_prompt when provided" do
      custom_prompt = "Use brutalist design with sharp edges"
      stub = stub_request(:post, gemini_endpoint)
        .with(
          query: { key: api_key },
          body: /SLIDE DESIGN PRINCIPLES.*brutalist design/m
        )
        .to_return(status: 200, body: llm_success_response, headers: { "Content-Type" => "application/json" })

      service.assemble(grimoire_text: grimoire_text, slide_text: slide_text, slide_prompt: custom_prompt)
      expect(stub).to have_been_requested
    end
  end
end
