class GeminiImageProvider
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
  DEFAULT_MODEL = "gemini-3.1-flash-image-preview"

  class Error < StandardError; end
  class RateLimitError < Error; end
  class ServerError < Error; end
  class ClientError < Error; end

  def initialize(api_key:, model: DEFAULT_MODEL)
    @api_key = api_key
    @model = model
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  # Returns { image_data: "<base64>", mime_type: "image/png" }
  def generate(prompt:, aspect_ratio: "16:9")
    response = @conn.post("models/#{@model}:generateContent", request_body(prompt, aspect_ratio)) do |req|
      req.params["key"] = @api_key
    end

    handle_errors!(response)
    extract_image(response.body)
  end

  private

  def request_body(prompt, aspect_ratio)
    {
      contents: [
        { parts: [ { text: prompt } ] }
      ],
      generationConfig: {
        responseModalities: [ "IMAGE" ],
        imageConfig: {
          aspectRatio: aspect_ratio
        }
      }
    }
  end

  def handle_errors!(response)
    case response.status
    when 200..299
      # success
    when 429
      raise RateLimitError, error_message(response)
    when 400..499
      raise ClientError, error_message(response)
    when 500..599
      raise ServerError, error_message(response)
    else
      raise Error, "Unexpected response status: #{response.status}"
    end
  end

  def error_message(response)
    body = response.body
    if body.is_a?(Hash) && body["error"]
      body["error"]["message"] || body["error"].to_s
    else
      "HTTP #{response.status}"
    end
  end

  def extract_image(body)
    candidates = body["candidates"] || []
    parts = candidates.dig(0, "content", "parts") || []

    image_part = parts.find { |p| p["inlineData"] }
    raise Error, "No image data in response" unless image_part

    {
      image_data: image_part["inlineData"]["data"],
      mime_type: image_part["inlineData"]["mimeType"]
    }
  end
end
