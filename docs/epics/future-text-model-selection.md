# Epic: Text Model Selection & Multi-Provider LLM Support

**Status:** Backlog
**Phase:** Future
**Depends on:** Settings & BYOK Configuration (Epic 3), Generation Engine (Epic 7 — Story 7.2 Prompt Assembly)
**Blocks:** v0.2 AI Assists (expand theme, generate slides from outline)

## Goal

Let users choose which text LLM powers prompt assembly and AI assists. Support multiple providers — Anthropic (Claude), OpenAI (GPT), and Google (Gemini) — behind a common interface, so the rest of the app never talks to a specific API directly. Include Ollama for local/offline text generation. The Setting model gains a `text_model` selector, and API key management adapts based on the chosen provider (Gemini text can share the existing Nano Banana API key).

## Context

Currently `PromptAssemblyService` (Story 7.2) calls a single LLM API using the `llm_api_key` stored in Settings. This epic extracts that into a provider abstraction — mirroring the pattern established by `GeminiImageProvider` for image generation — and adds support for five models across four providers:

| Provider  | Model               | API Key Field         | Notes |
|-----------|---------------------|-----------------------|-------|
| Anthropic | Claude Opus 4.6     | `llm_api_key`         | Most capable, highest cost |
| Anthropic | Claude Sonnet 4.6   | `llm_api_key`         | Good balance of quality and speed |
| OpenAI    | GPT-5.2             | `llm_api_key`         | Alternative provider |
| Google AI | Gemini 3 Flash      | `nano_banana_api_key` | Shares key with image gen; fastest/cheapest |
| Google AI | Gemini 3.1 Pro      | `nano_banana_api_key` | Shares key with image gen; higher quality |
| Ollama    | (user-configured)   | None                  | Local; no API key needed |

## Stories

### Story F1.1: LLM Provider Interface & Registry

**Description:** Define the common interface that all text LLM providers must implement, and build a registry that resolves a model identifier string (e.g., `"anthropic/claude-sonnet-4.6"`) into an instantiated provider. The interface mirrors the simplicity of `GeminiImageProvider` — each provider is a plain Ruby class with a constructor that takes credentials and a `#chat` method.

The common interface:

```ruby
# All providers implement:
provider.chat(messages:, system:)
# => { content: "The assembled prompt text..." }
#
# messages: Array of { role: "user"|"assistant", content: "..." }
# system:   String — the system prompt (provider maps this to its API's format)
#
# Raises:
#   Provider::AuthenticationError — invalid/missing API key
#   Provider::RateLimitError      — HTTP 429 / rate limit hit
#   Provider::ServerError         — 5xx from upstream
#   Provider::Error               — catch-all
```

The registry:

```ruby
LlmProvider.for("anthropic/claude-sonnet-4.6", api_key: key)
# => #<AnthropicProvider model="claude-sonnet-4.6" ...>
```

**Outputs:**
- `app/services/llm_provider.rb` — base module with `Error`, `AuthenticationError`, `RateLimitError`, `ServerError` exception classes, `.for` registry method, and `AVAILABLE_MODELS` constant
- `spec/services/llm_provider_spec.rb`

**Acceptance criteria:**
- [ ] `LlmProvider::AVAILABLE_MODELS` returns a list of `{ id:, label:, provider:, api_key_field: }` hashes for all supported models
- [ ] `LlmProvider.for(model_id, api_key:)` returns the correct provider instance
- [ ] `LlmProvider.for` raises `ArgumentError` for unknown model identifiers
- [ ] All provider error classes inherit from `LlmProvider::Error`
- [ ] Tests pass

**Dependencies:** None

---

### Story F1.2: Anthropic Provider (Claude Opus 4.6, Claude Sonnet 4.6)

**Description:** Implement `AnthropicProvider` calling the Anthropic Messages API. Uses Faraday (consistent with `GeminiImageProvider`). Supports both Claude Opus 4.6 (`claude-opus-4-6-20260301`) and Claude Sonnet 4.6 (`claude-sonnet-4-6-20260301`).

**API details:**

- **Base URL:** `https://api.anthropic.com`
- **Endpoint:** `POST /v1/messages`
- **Authentication:** `x-api-key` header (not Bearer token)
- **Required headers:**
  - `x-api-key: {api_key}`
  - `anthropic-version: 2023-06-01`
  - `content-type: application/json`
- **Request body:**
  ```json
  {
    "model": "claude-sonnet-4-6-20260301",
    "max_tokens": 1024,
    "system": "You are a prompt assembly assistant...",
    "messages": [
      { "role": "user", "content": "Merge this theme and slide..." }
    ]
  }
  ```
- **Success response (200):**
  ```json
  {
    "id": "msg_...",
    "type": "message",
    "role": "assistant",
    "content": [
      { "type": "text", "text": "A cinematic wide shot of..." }
    ],
    "stop_reason": "end_turn",
    "usage": { "input_tokens": 245, "output_tokens": 87 }
  }
  ```
- **Error responses:** 401 (invalid key), 429 (rate limit with `retry-after` header), 529 (overloaded), 500 (server error)
- **Non-streaming only** for v1 — no SSE, just a synchronous POST. Streaming can be added later by setting `"stream": true` and handling SSE events.

**Outputs:**
- `app/services/anthropic_provider.rb`
- `spec/services/anthropic_provider_spec.rb` (stubbed HTTP)

**Acceptance criteria:**
- [ ] `AnthropicProvider.new(api_key:, model:).chat(messages:, system:)` returns `{ content: "..." }`
- [ ] Sends correct headers: `x-api-key`, `anthropic-version: 2023-06-01`
- [ ] Maps the `system:` argument into the top-level `system` field (not inside `messages`)
- [ ] Extracts the text from `response["content"][0]["text"]`
- [ ] Raises `LlmProvider::AuthenticationError` on 401
- [ ] Raises `LlmProvider::RateLimitError` on 429 and 529 (overloaded)
- [ ] Raises `LlmProvider::ServerError` on 500/502/503
- [ ] Defaults `max_tokens` to 1024 (sufficient for prompt assembly); accepts override
- [ ] Works with both `claude-opus-4-6-20260301` and `claude-sonnet-4-6-20260301` model strings
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

---

### Story F1.3: OpenAI Provider (GPT-5.2)

**Description:** Implement `OpenAiProvider` calling the OpenAI Chat Completions API. The model string is `gpt-5.2`.

**API details:**

- **Base URL:** `https://api.openai.com`
- **Endpoint:** `POST /v1/chat/completions`
- **Authentication:** `Authorization: Bearer {api_key}` header
- **Required headers:**
  - `Authorization: Bearer {api_key}`
  - `Content-Type: application/json`
- **Request body:**
  ```json
  {
    "model": "gpt-5.2",
    "messages": [
      { "role": "system", "content": "You are a prompt assembly assistant..." },
      { "role": "user", "content": "Merge this theme and slide..." }
    ],
    "max_completion_tokens": 1024
  }
  ```
  Note: OpenAI places the system prompt as the first message with `"role": "system"` inside the `messages` array, unlike Anthropic which uses a top-level `system` field.
- **Success response (200):**
  ```json
  {
    "id": "chatcmpl-...",
    "object": "chat.completion",
    "choices": [
      {
        "index": 0,
        "message": {
          "role": "assistant",
          "content": "A cinematic wide shot of..."
        },
        "finish_reason": "stop"
      }
    ],
    "usage": { "prompt_tokens": 245, "completion_tokens": 87, "total_tokens": 332 }
  }
  ```
- **Error responses:** 401 (invalid key), 429 (rate limit), 500/502/503 (server errors)
- **Non-streaming only** for v1 — set `"stream": false` (default). Streaming can be added later by setting `"stream": true` and handling SSE events.

**Outputs:**
- `app/services/open_ai_provider.rb`
- `spec/services/open_ai_provider_spec.rb` (stubbed HTTP)

**Acceptance criteria:**
- [ ] `OpenAiProvider.new(api_key:, model:).chat(messages:, system:)` returns `{ content: "..." }`
- [ ] Sends `Authorization: Bearer {api_key}` header
- [ ] Prepends the `system:` argument as a `{ role: "system", content: system }` message at the beginning of the messages array
- [ ] Extracts text from `response["choices"][0]["message"]["content"]`
- [ ] Raises `LlmProvider::AuthenticationError` on 401
- [ ] Raises `LlmProvider::RateLimitError` on 429
- [ ] Raises `LlmProvider::ServerError` on 500/502/503
- [ ] Defaults `max_completion_tokens` to 1024; accepts override
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

---

### Story F1.4: Gemini Text Provider (Gemini 3 Flash, Gemini 3.1 Pro)

**Description:** Implement `GeminiTextProvider` calling the Google AI Gemini API for text generation. This uses the same API base URL and authentication as `GeminiImageProvider` but requests text-only responses. The Gemini API key is the same `nano_banana_api_key` used for image generation — users do not need a separate key.

**API details:**

- **Base URL:** `https://generativelanguage.googleapis.com/v1beta`
- **Endpoint:** `POST /models/{model}:generateContent?key={api_key}`
- **Authentication:** API key as query parameter (same as image provider)
- **Models:** `gemini-3-flash` (fast/cheap), `gemini-3.1-pro` (higher quality)
- **Request body:**
  ```json
  {
    "contents": [
      { "role": "user", "parts": [{ "text": "Merge this theme and slide..." }] }
    ],
    "systemInstruction": {
      "parts": [{ "text": "You are a prompt assembly assistant..." }]
    },
    "generationConfig": {
      "maxOutputTokens": 1024
    }
  }
  ```
  Note: Gemini uses `systemInstruction` as a top-level field (similar to Anthropic, not inside `contents`). Multi-turn conversations use alternating `"role": "user"` and `"role": "model"` entries in `contents`.
- **Success response (200):**
  ```json
  {
    "candidates": [
      {
        "content": {
          "parts": [{ "text": "A cinematic wide shot of..." }],
          "role": "model"
        },
        "finishReason": "STOP"
      }
    ],
    "usageMetadata": { "promptTokenCount": 245, "candidatesTokenCount": 87, "totalTokenCount": 332 }
  }
  ```
- **Error responses:** 400 (bad request), 403 (invalid key), 429 (rate limit), 500 (server error)
- **Non-streaming only** for v1. Streaming would use the `streamGenerateContent` endpoint instead.

**Outputs:**
- `app/services/gemini_text_provider.rb`
- `spec/services/gemini_text_provider_spec.rb` (stubbed HTTP)

**Acceptance criteria:**
- [ ] `GeminiTextProvider.new(api_key:, model:).chat(messages:, system:)` returns `{ content: "..." }`
- [ ] Passes API key as query parameter `key=` (consistent with `GeminiImageProvider`)
- [ ] Maps `system:` to the `systemInstruction` top-level field
- [ ] Maps `messages` role values: `"assistant"` becomes `"model"` in the Gemini `contents` array
- [ ] Extracts text from `response["candidates"][0]["content"]["parts"][0]["text"]`
- [ ] Raises `LlmProvider::AuthenticationError` on 403
- [ ] Raises `LlmProvider::RateLimitError` on 429
- [ ] Raises `LlmProvider::ServerError` on 500
- [ ] Does NOT make requests with `responseModalities: ["IMAGE"]` (text-only generation)
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

---

### Story F1.5: Ollama Provider (Local Text Generation)

**Description:** Implement `OllamaTextProvider` for running LLMs locally via Ollama. Ollama exposes an OpenAI-compatible chat completions API on localhost, so this provider is structurally similar to `OpenAiProvider` but targets `http://localhost:11434` with no authentication. The user specifies which local model to use (e.g., `llama3.3`, `mistral`, `gemma3`) in Settings.

**API details:**

- **Base URL:** `http://localhost:11434` (configurable via `OLLAMA_HOST` env var)
- **Endpoint:** `POST /api/chat`
- **Authentication:** None
- **Request body:**
  ```json
  {
    "model": "llama3.3",
    "messages": [
      { "role": "system", "content": "You are a prompt assembly assistant..." },
      { "role": "user", "content": "Merge this theme and slide..." }
    ],
    "stream": false
  }
  ```
  Note: Ollama's `/api/chat` endpoint uses the same message format as OpenAI (system role inside messages array). Setting `"stream": false` returns a single JSON response instead of streaming.
- **Success response (200):**
  ```json
  {
    "model": "llama3.3",
    "message": {
      "role": "assistant",
      "content": "A cinematic wide shot of..."
    },
    "done": true,
    "total_duration": 1234567890
  }
  ```
- **Error responses:** Connection refused (Ollama not running), 404 (model not pulled), 500 (generation error)
- **Timeout considerations:** Local models can be slow, especially on first load. Use a longer Faraday timeout (120s vs the 30s default for cloud providers).

**Outputs:**
- `app/services/ollama_text_provider.rb`
- `spec/services/ollama_text_provider_spec.rb` (stubbed HTTP)

**Acceptance criteria:**
- [ ] `OllamaTextProvider.new(model:).chat(messages:, system:)` returns `{ content: "..." }` — no `api_key` parameter required
- [ ] Sends requests to `http://localhost:11434/api/chat` by default
- [ ] Respects `ENV["OLLAMA_HOST"]` for custom host/port
- [ ] Prepends `system:` as a `{ role: "system" }` message (same as OpenAI format)
- [ ] Sets `"stream": false` to get a single JSON response
- [ ] Extracts text from `response["message"]["content"]`
- [ ] Raises `LlmProvider::Error` with a helpful message when connection is refused (Ollama not running)
- [ ] Raises `LlmProvider::Error` when the model is not found (404 — suggests running `ollama pull {model}`)
- [ ] Uses a 120-second request timeout (local models can be slow on first load)
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

---

### Story F1.6: Setting Model — Text Model Selection & Migration

**Description:** Add a `text_model` column to the Setting model that stores the selected model identifier (e.g., `"anthropic/claude-sonnet-4.6"`). When the provider is Ollama, also store the local model name in a new `ollama_text_model` column. Update `Setting.current` to expose a helper method that resolves the selected model into an instantiated provider.

**Outputs:**
- `db/migrate/..._add_text_model_to_settings.rb`
- Updated `app/models/setting.rb`
- `spec/models/setting_spec.rb` (updated)

**Migration:**

```ruby
add_column :settings, :text_model, :string, default: "anthropic/claude-sonnet-4.6"
add_column :settings, :ollama_text_model, :string, default: "llama3.3"
```

**Acceptance criteria:**
- [ ] `Setting` has `text_model` column with default `"anthropic/claude-sonnet-4.6"`
- [ ] `Setting` has `ollama_text_model` column with default `"llama3.3"` (used only when text_model is `"ollama"`)
- [ ] `Setting#text_provider` returns an instantiated LLM provider based on `text_model`, passing the correct API key:
  - Anthropic models use `llm_api_key`
  - OpenAI models use `llm_api_key`
  - Gemini models use `nano_banana_api_key` (shared with image gen)
  - Ollama uses no key, reads model from `ollama_text_model`
- [ ] `Setting#text_provider` raises a clear error if the required API key is blank
- [ ] Existing settings rows get the default `text_model` value on migration
- [ ] Tests pass

**Dependencies:** Stories F1.1 through F1.5

---

### Story F1.7: Settings UI — Text Model Selector

**Description:** Add a "Text Model" section to the Settings page with a dropdown that lists all available models grouped by provider. The dropdown shows human-readable labels (e.g., "Anthropic -- Claude Sonnet 4.6"). When the selected model changes, the API key guidance updates to indicate which key field is used. When Ollama is selected, show an additional text field for the local model name.

**Inputs:**
- `app/views/settings/show.html.erb` (existing settings form)
- `LlmProvider::AVAILABLE_MODELS` from Story F1.1

**Outputs:**
- Updated `app/views/settings/show.html.erb`
- Updated `app/controllers/settings_controller.rb` (permit new params)
- Stimulus controller for dynamic UI updates (optional — can also use a full page approach)

**Acceptance criteria:**
- [ ] Settings page shows a "Text Model" dropdown between the API Keys section and the Defaults section
- [ ] Dropdown options are grouped by provider: "Anthropic", "OpenAI", "Google AI", "Ollama (Local)"
- [ ] Available options:
  - Anthropic -- Claude Opus 4.6
  - Anthropic -- Claude Sonnet 4.6
  - OpenAI -- GPT-5.2
  - Google AI -- Gemini 3 Flash
  - Google AI -- Gemini 3.1 Pro
  - Ollama (Local) -- Custom Model
- [ ] Below the dropdown, a hint line indicates which API key is used: "Uses LLM API key" for Anthropic/OpenAI, "Uses Nano Banana API key (shared with image generation)" for Google AI, "No API key required -- runs locally" for Ollama
- [ ] When "Ollama (Local)" is selected, an additional text input appears for the Ollama model name (e.g., `llama3.3`, `mistral`, `gemma3`)
- [ ] Saving the form persists `text_model` (and `ollama_text_model` if applicable)
- [ ] Controller permits `text_model` and `ollama_text_model` params
- [ ] Tests pass

**Dependencies:** Story F1.6

---

### Story F1.8: Wire PromptAssemblyService to Provider Abstraction

**Description:** Update `PromptAssemblyService` to use `Setting.current.text_provider` instead of directly calling any specific LLM API. This is the integration point — after this story, changing the text model in Settings immediately changes which LLM assembles prompts.

**Inputs:**
- `app/services/prompt_assembly_service.rb` from Epic 7, Story 7.2
- `Setting#text_provider` from Story F1.6

**Outputs:**
- Updated `app/services/prompt_assembly_service.rb`
- Updated `spec/services/prompt_assembly_service_spec.rb`

**Acceptance criteria:**
- [ ] `PromptAssemblyService` calls `Setting.current.text_provider.chat(messages:, system:)` instead of any provider-specific API
- [ ] The system prompt and message structure for prompt assembly remain unchanged
- [ ] Fallback behavior is preserved: if the LLM call fails, return a concatenation of grimoire_text + slide_text
- [ ] All `LlmProvider::Error` subclasses are caught by the fallback
- [ ] Existing tests continue to pass (with provider stubbed at the interface level)
- [ ] New test: swapping `text_model` in Settings changes which provider is instantiated

**Dependencies:** Story F1.6, Epic 7 Story 7.2

---

## Implementation Order

1. **Story F1.1** -- Provider interface and registry are the foundation everything else builds on
2. **Stories F1.2, F1.3, F1.4, F1.5** -- Provider implementations are independent of each other and can be built in parallel
3. **Story F1.6** -- Setting migration wires the model selection into the data layer; needs all providers
4. **Story F1.7** -- Settings UI depends on the Setting model changes
5. **Story F1.8** -- Integration with PromptAssemblyService is the final connection; depends on the Setting model having `text_provider`

## Future Considerations

- **Streaming responses:** All four providers support streaming (SSE for Anthropic/OpenAI, SSE via `streamGenerateContent` for Gemini, streaming JSON for Ollama). This would improve perceived latency for AI assists in v0.2 where the user sees the LLM output directly. Not needed for prompt assembly since the result is consumed by the backend.
- **Cost tracking:** Each provider response includes token usage metadata. When cost tracking is implemented (v0.2), the provider interface should be extended to return `{ content:, usage: { input_tokens:, output_tokens: } }`.
- **Provider health checks:** A "Test connection" button in Settings that calls the selected provider with a minimal prompt to verify the API key works before the user tries to generate.
- **Additional models:** The registry pattern makes it trivial to add new models — just add a new entry to `AVAILABLE_MODELS` and implement (or reuse) a provider class. Future candidates: Anthropic Claude Haiku (fast/cheap), OpenAI GPT-5.2 Mini, Mistral models via API.
