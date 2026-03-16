class PromptAssemblyService
  GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
  DEFAULT_MODEL = "gemini-2.5-flash"

  SYSTEM_PROMPT = <<~PROMPT
    You are an expert at writing image generation prompts. Given a visual theme description (grimoire) and a slide description, combine them into a single, effective image generation prompt.

    The output should be a detailed visual description optimized for an AI image generator. Focus on:
    - Visual style, colors, textures, and mood from the theme
    - The specific content and composition described for the slide
    - Typography style and placement if mentioned
    - Aspect ratio and layout considerations

    Output ONLY the image generation prompt, nothing else. No explanations, no preamble.
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

  def assemble(grimoire_text:, slide_text:, refinement: nil)
    return fallback_prompt(grimoire_text, slide_text, refinement) if @api_key.blank?

    user_message = build_user_message(grimoire_text, slide_text, refinement)

    response = @conn.post("models/#{@model}:generateContent", request_body(user_message)) do |req|
      req.params["key"] = @api_key
    end

    if response.status == 200
      extract_text(response.body)
    else
      fallback_prompt(grimoire_text, slide_text, refinement)
    end
  rescue Faraday::Error
    fallback_prompt(grimoire_text, slide_text, refinement)
  end

  private

  def build_user_message(grimoire_text, slide_text, refinement)
    parts = []
    parts << "THEME (Grimoire):\n#{grimoire_text}"
    parts << "SLIDE DESCRIPTION:\n#{slide_text}"
    parts << "REFINEMENT:\n#{refinement}" if refinement.present?
    parts.join("\n\n")
  end

  def request_body(user_message)
    {
      contents: [
        { role: "user", parts: [ { text: "#{SYSTEM_PROMPT}\n\n#{user_message}" } ] }
      ]
    }
  end

  def extract_text(body)
    candidates = body["candidates"] || []
    parts = candidates.dig(0, "content", "parts") || []
    text_part = parts.find { |p| p["text"] }
    text_part&.dig("text") || ""
  end

  def fallback_prompt(grimoire_text, slide_text, refinement)
    parts = [ "Visual theme: #{grimoire_text}", "Slide content: #{slide_text}" ]
    parts << "Refinement: #{refinement}" if refinement.present?
    parts.join("\n\n")
  end
end
