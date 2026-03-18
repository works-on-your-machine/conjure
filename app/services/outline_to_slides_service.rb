class OutlineToSlidesService
  GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
  DEFAULT_MODEL = "gemini-3-flash-preview"

  SYSTEM_PROMPT = <<~PROMPT
    You are an expert at breaking down presentation outlines into individual slide descriptions.

    Given a brain dump, outline, bullet points, or rough notes, break it into individual slides.
    Each slide needs a short title and a description of what the slide should visually communicate.

    The description should focus on the VISUAL content — what should the slide image look like,
    what should it convey, what mood or energy it should have. Not speaker notes.

    Respond with ONLY valid JSON — an array of objects with "title" and "description" keys.
    No markdown, no code fences, no explanation. Just the JSON array.

    Example output:
    [
      {"title": "The problem", "description": "Show the core tension. Breaking news style. What everyone assumes vs what's actually happening."},
      {"title": "The solution", "description": "The reveal moment. Clean, confident, optimistic. The new way forward."}
    ]
  PROMPT

  def initialize(api_key:, model: DEFAULT_MODEL)
    @api_key = api_key
    @model = model
    @conn = Faraday.new(url: GEMINI_BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  # Returns array of { title:, description: } hashes
  def generate(outline_text)
    return fallback_parse(outline_text) if @api_key.blank?

    response = @conn.post("models/#{@model}:generateContent", request_body(outline_text)) do |req|
      req.params["key"] = @api_key
    end

    if response.status == 200
      parse_response(response.body)
    else
      fallback_parse(outline_text)
    end
  rescue => e
    Rails.logger.error("OutlineToSlidesService failed: #{e.message}")
    fallback_parse(outline_text)
  end

  private

  def request_body(outline_text)
    {
      contents: [
        { role: "user", parts: [ { text: "#{SYSTEM_PROMPT}\n\nOUTLINE:\n#{outline_text}" } ] }
      ]
    }
  end

  def parse_response(body)
    text = body.dig("candidates", 0, "content", "parts", 0, "text") || ""
    # Strip markdown code fences if present
    text = text.gsub(/```json\s*/i, "").gsub(/```\s*/, "").strip
    slides = JSON.parse(text)
    slides.map { |s| { title: s["title"], description: s["description"] } }
  rescue JSON::ParserError
    fallback_parse(text)
  end

  # Simple fallback: split on newlines, each line becomes a slide
  def fallback_parse(text)
    text.split("\n").map(&:strip).reject(&:blank?).map.with_index do |line, i|
      line = line.sub(/^[-*•\d.)\s]+/, "").strip # Remove bullet markers
      { title: "Slide #{i + 1}", description: line }
    end
  end
end
