class PromptAssemblyService
  GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
  DEFAULT_MODEL = "gemini-3-flash-preview"

  DEFAULT_SLIDE_PROMPT = <<~SLIDE_PROMPT.freeze
    A good presentation slide communicates one idea with total clarity and lets everything else recede. The most reliable way to achieve this is through deliberate contrast — not just color contrast, but contrast between density and whitespace, between large and small type, between what's emphasized and what's structural. Information should appear in intentional clumps rather than distributed evenly across the slide; related elements sit close together, unrelated elements are separated by genuine space. Typography carries most of the hierarchy: two weights and one size difference can do more work than color, icons, or decorative elements. When color is used, it should mean something specific — one accent color used once per slide for the single most important element, never decoratively.

    The slide should know what kind of slide it is and commit to that fully. A data slide is different from a quote slide is different from a narrative slide — each has its own geometry and its own logic for where the eye should go first, second, and last. Structural elements like rules, columns, and metadata bars should be consistent enough across slides that the audience stops noticing them and just absorbs the content. And every element on the slide should be able to answer the question: why is this here? — if it can't, it shouldn't be there.
  SLIDE_PROMPT

  SYSTEM_PROMPT = <<~PROMPT
    You are an expert at writing image generation prompts for presentation slides. Given a visual theme description (grimoire), a slide description, and slide design principles, combine them into a single, effective image generation prompt.

    The output should be a detailed visual description optimized for an AI image generator. Focus on:
    - Visual style, colors, textures, and mood from the theme
    - The specific content and composition described for the slide
    - Typography style and placement if mentioned
    - Aspect ratio and layout considerations
    - The slide design principles provided — use them to guide layout, hierarchy, and composition

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

  def assemble(grimoire_text:, slide_text:, refinement: nil, slide_prompt: nil)
    return fallback_prompt(grimoire_text, slide_text, refinement) if @api_key.blank?

    user_message = build_user_message(grimoire_text, slide_text, refinement, slide_prompt)

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

  def build_user_message(grimoire_text, slide_text, refinement, slide_prompt)
    parts = []
    parts << "SLIDE DESIGN PRINCIPLES:\n#{slide_prompt.presence || DEFAULT_SLIDE_PROMPT}"
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
