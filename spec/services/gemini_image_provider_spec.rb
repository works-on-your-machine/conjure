require "rails_helper"

RSpec.describe GeminiImageProvider do
  let(:api_key) { "test-gemini-api-key" }
  let(:provider) { described_class.new(api_key: api_key) }
  let(:endpoint) { "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent" }

  let(:success_response) do
    {
      candidates: [
        {
          content: {
            parts: [
              {
                inlineData: {
                  mimeType: "image/png",
                  data: Base64.strict_encode64("fake-image-data")
                }
              }
            ]
          }
        }
      ]
    }.to_json
  end

  describe "#generate" do
    it "returns image data on success" do
      stub_request(:post, endpoint)
        .with(query: { key: api_key })
        .to_return(status: 200, body: success_response, headers: { "Content-Type" => "application/json" })

      result = provider.generate(prompt: "A dramatic title card", aspect_ratio: "16:9")

      expect(result[:image_data]).to eq(Base64.strict_encode64("fake-image-data"))
      expect(result[:mime_type]).to eq("image/png")
    end

    it "sends the correct request payload" do
      stub = stub_request(:post, endpoint)
        .with(
          query: { key: api_key },
          body: hash_including(
            "contents" => [
              { "parts" => [{ "text" => "A dramatic title card" }] }
            ],
            "generationConfig" => hash_including(
              "responseModalities" => [ "IMAGE" ]
            )
          )
        )
        .to_return(status: 200, body: success_response, headers: { "Content-Type" => "application/json" })

      provider.generate(prompt: "A dramatic title card", aspect_ratio: "16:9")
      expect(stub).to have_been_requested
    end

    it "includes aspect ratio in image config" do
      stub = stub_request(:post, endpoint)
        .with(
          query: { key: api_key },
          body: hash_including(
            "generationConfig" => hash_including(
              "imageConfig" => hash_including("aspectRatio" => "4:3")
            )
          )
        )
        .to_return(status: 200, body: success_response, headers: { "Content-Type" => "application/json" })

      provider.generate(prompt: "A slide", aspect_ratio: "4:3")
      expect(stub).to have_been_requested
    end

    it "raises RateLimitError on HTTP 429" do
      stub_request(:post, endpoint)
        .with(query: { key: api_key })
        .to_return(status: 429, body: '{"error":{"message":"Rate limited"}}')

      expect {
        provider.generate(prompt: "test", aspect_ratio: "16:9")
      }.to raise_error(GeminiImageProvider::RateLimitError)
    end

    it "raises ServerError on HTTP 5xx" do
      stub_request(:post, endpoint)
        .with(query: { key: api_key })
        .to_return(status: 500, body: '{"error":{"message":"Internal error"}}')

      expect {
        provider.generate(prompt: "test", aspect_ratio: "16:9")
      }.to raise_error(GeminiImageProvider::ServerError)
    end

    it "raises ClientError on HTTP 4xx (not 429)" do
      stub_request(:post, endpoint)
        .with(query: { key: api_key })
        .to_return(status: 400, body: '{"error":{"message":"Bad request"}}')

      expect {
        provider.generate(prompt: "test", aspect_ratio: "16:9")
      }.to raise_error(GeminiImageProvider::ClientError)
    end

    it "raises ClientError on HTTP 401" do
      stub_request(:post, endpoint)
        .with(query: { key: api_key })
        .to_return(status: 401, body: '{"error":{"message":"Unauthorized"}}')

      expect {
        provider.generate(prompt: "test", aspect_ratio: "16:9")
      }.to raise_error(GeminiImageProvider::ClientError)
    end
  end

  describe "#generate with custom model" do
    it "allows overriding the model" do
      custom_provider = described_class.new(api_key: api_key, model: "gemini-2.5-flash-image")
      custom_endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

      stub_request(:post, custom_endpoint)
        .with(query: { key: api_key })
        .to_return(status: 200, body: success_response, headers: { "Content-Type" => "application/json" })

      result = custom_provider.generate(prompt: "test", aspect_ratio: "16:9")
      expect(result[:image_data]).to be_present
    end
  end
end
