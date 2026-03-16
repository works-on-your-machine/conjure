# Epic: Future Image Provider Options

**Status:** Backlog
**Phase:** Future
**Depends on:** Generation Engine (Epic 7), Settings (Epic 3)

## Goal

Expand Conjure beyond its single Gemini (Nano Banana) image provider to support multiple image generation backends -- both cloud APIs and local generation via Ollama. Users should be able to choose their preferred provider, configure provider-specific settings (API keys, endpoints, models), and switch between providers without losing any existing functionality. Every new provider implements the same interface: `generate(prompt:, aspect_ratio:)` returning `{ image_data:, mime_type: }`.

## Context: Current Provider Interface

The existing `GeminiImageProvider` establishes the contract that all new providers must follow:

```ruby
provider = GeminiImageProvider.new(api_key: "...")
result = provider.generate(prompt: "a mountain landscape", aspect_ratio: "16:9")
# => { image_data: "<base64-encoded PNG>", mime_type: "image/png" }
```

Error handling follows the same pattern: `RateLimitError`, `ServerError`, `ClientError` subclasses of a base `Error`. Any new provider should raise equivalent errors so the retry logic in `VisionGenerationJob` works unchanged.

---

## Stories

### Story F1.1: Provider Interface Extraction & Registry

**Description:** Before adding new providers, extract the implicit interface into an explicit base class or module, and create a provider registry that maps provider names to classes. This gives us a single place to look up providers by name (needed for the settings UI and job dispatch) and ensures every provider implements the required methods.

**Outputs:**
- `app/services/image_provider_base.rb` -- abstract base class with `generate(prompt:, aspect_ratio:)` raising `NotImplementedError`, plus the shared error class hierarchy (`Error`, `RateLimitError`, `ServerError`, `ClientError`)
- `app/services/image_provider_registry.rb` -- maps provider keys (`:gemini`, `:openai_dalle`, `:flux_bfl`, `:stability_ai`, `:ollama`) to their classes
- Updated `GeminiImageProvider` to inherit from `ImageProviderBase`
- Updated `VisionGenerationJob` to resolve the provider from the registry based on `Setting.current`

**Acceptance criteria:**
- [ ] `ImageProviderBase` defines the interface contract; calling `generate` on it directly raises `NotImplementedError`
- [ ] All error classes (`Error`, `RateLimitError`, `ServerError`, `ClientError`) live on `ImageProviderBase` and are inherited by subclasses
- [ ] `ImageProviderRegistry.provider_for(:gemini)` returns `GeminiImageProvider`
- [ ] `ImageProviderRegistry.available_providers` returns a hash of `{ key => display_name }` for all registered providers
- [ ] `GeminiImageProvider` inherits from `ImageProviderBase` and continues to pass all existing tests
- [ ] `VisionGenerationJob` uses the registry to instantiate the active provider from settings
- [ ] Tests pass

**Dependencies:** None (within this epic)

---

### Story F1.2: OpenAI DALL-E Provider

**Description:** Build an `OpenAiDalleProvider` that generates images via the OpenAI Images API. OpenAI currently offers two image generation models:

- **DALL-E 3** -- Available via `POST https://api.openai.com/v1/images/generations`. Supports sizes `1024x1024`, `1024x1792` (portrait), and `1792x1024` (landscape). Returns either a URL or base64 JSON depending on the `response_format` parameter. Pricing is approximately $0.040/image at 1024x1024 standard quality, $0.080/image at 1024x1024 HD quality, and $0.120/image at 1792x1024 HD quality.
- **GPT Image 1 (gpt-image-1)** -- OpenAI's newer image generation model, available via `POST https://api.openai.com/v1/images/generations`. Supports sizes `1024x1024`, `1024x1536`, `1536x1024`, and `auto`. Returns base64-encoded image data in PNG or WebP format. Pricing varies by quality tier: approximately $0.011/image at low quality (1024x1024), $0.042/image at medium quality, and $0.167/image at high quality (1536x1024). Supports `background` parameter (`transparent` or `opaque`) and `moderation` parameter (`auto` or `low`).

The provider should map Conjure's aspect ratio values to the closest supported size for whichever model is selected.

**API details:**
- Endpoint: `POST https://api.openai.com/v1/images/generations`
- Auth: `Authorization: Bearer <api_key>` header
- Request body:
  ```json
  {
    "model": "gpt-image-1",
    "prompt": "...",
    "n": 1,
    "size": "1536x1024",
    "quality": "medium"
  }
  ```
- Response (gpt-image-1): `{ "data": [{ "b64_json": "<base64>" }] }`
- Response (dall-e-3, with `response_format: "b64_json"`): `{ "data": [{ "b64_json": "<base64>", "revised_prompt": "..." }] }`
- DALL-E 3 automatically rewrites prompts for better results; the rewritten prompt is returned as `revised_prompt`
- Rate limits: Varies by API tier; returns HTTP 429 with `Retry-After` header

**Aspect ratio mapping:**
| Conjure ratio | DALL-E 3 size | GPT Image 1 size |
|---------------|---------------|------------------|
| 16:9          | 1792x1024     | 1536x1024        |
| 9:16          | 1024x1792     | 1024x1536        |
| 1:1           | 1024x1024     | 1024x1024        |
| 4:3           | 1792x1024     | 1536x1024        |
| 3:4           | 1024x1792     | 1024x1536        |

**Outputs:**
- `app/services/open_ai_dalle_provider.rb`
- `spec/services/open_ai_dalle_provider_spec.rb`
- Registration in `ImageProviderRegistry`

**Acceptance criteria:**
- [ ] `OpenAiDalleProvider.new(api_key:, model: "gpt-image-1").generate(prompt:, aspect_ratio:)` returns `{ image_data:, mime_type: }`
- [ ] Supports both `dall-e-3` and `gpt-image-1` models via a `model:` parameter (default: `gpt-image-1`)
- [ ] Maps Conjure aspect ratios to the nearest supported size for the selected model
- [ ] Requests base64 response format; returns decoded base64 image data
- [ ] Raises `RateLimitError` on HTTP 429, `ClientError` on 4xx, `ServerError` on 5xx
- [ ] Registered in `ImageProviderRegistry` as `:openai_dalle`
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

---

### Story F1.3: Black Forest Labs Flux Provider

**Description:** Build a `FluxBflProvider` that generates images via the Black Forest Labs (BFL) API. BFL is the creator of the Flux family of models, widely regarded for photorealism and prompt adherence.

**Available models (via BFL API):**
- **FLUX.1 Pro** -- Highest quality, best prompt adherence. Endpoint: `POST https://api.bfl.ml/v1/flux-pro-1.1`
- **FLUX.1 Dev** -- High quality, faster and cheaper. Endpoint: `POST https://api.bfl.ml/v1/flux-dev`
- **FLUX.1 Pro Ultra** -- Raw/ultra-high-resolution variant. Endpoint: `POST https://api.bfl.ml/v1/flux-pro-1.1-ultra`

**API details:**
- Auth: `X-Key: <api_key>` header
- The BFL API is asynchronous. Image generation is a two-step process:
  1. Submit a generation request: `POST https://api.bfl.ml/v1/<model-endpoint>` with JSON body `{ "prompt": "...", "width": 1024, "height": 768 }`. Returns `{ "id": "<task_id>" }`.
  2. Poll for the result: `GET https://api.bfl.ml/v1/get_result?id=<task_id>`. Returns `{ "status": "Ready", "result": { "sample": "<image_url>" } }` when complete, or `{ "status": "Pending" }` while processing.
- Images are returned as a URL to a hosted image (not inline base64). The provider must download the image and encode it to base64 to match our interface.
- Supports `width` and `height` parameters (not aspect ratio directly), so the provider must map ratios to pixel dimensions. Maximum dimensions vary by model but generally support up to 1440px on the long side.
- Pricing: approximately $0.04/image for FLUX.1 Pro 1.1, $0.025/image for FLUX.1 Dev, $0.06/image for FLUX.1 Pro Ultra. Pricing is credit-based.

**Aspect ratio mapping (targeting ~1 megapixel):**
| Conjure ratio | Width | Height |
|---------------|-------|--------|
| 16:9          | 1360  | 768    |
| 9:16          | 768   | 1360   |
| 1:1           | 1024  | 1024   |
| 4:3           | 1184  | 888    |
| 3:4           | 888   | 1184   |

**Outputs:**
- `app/services/flux_bfl_provider.rb`
- `spec/services/flux_bfl_provider_spec.rb`
- Registration in `ImageProviderRegistry`

**Acceptance criteria:**
- [ ] `FluxBflProvider.new(api_key:, model: "flux-pro-1.1").generate(prompt:, aspect_ratio:)` returns `{ image_data:, mime_type: }`
- [ ] Supports `flux-pro-1.1`, `flux-dev`, and `flux-pro-1.1-ultra` models via `model:` parameter
- [ ] Implements the two-step async flow: submit task, poll for result with exponential backoff
- [ ] Downloads the resulting image URL and returns it as base64-encoded data
- [ ] Raises `RateLimitError` on HTTP 429, `ClientError` on 4xx, `ServerError` on 5xx
- [ ] Times out with a descriptive error if polling exceeds 120 seconds
- [ ] Maps Conjure aspect ratios to appropriate width/height pixel dimensions
- [ ] Registered in `ImageProviderRegistry` as `:flux_bfl`
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

---

### Story F1.4: Stability AI Provider

**Description:** Build a `StabilityAiProvider` that generates images via the Stability AI REST API. Stability AI is the company behind the Stable Diffusion family of models.

**Available models (via Stability AI API at `https://api.stability.ai`):**
- **Stable Diffusion 3.5 Large** -- Highest quality SD model. 8B parameter model with excellent prompt adherence.
- **Stable Diffusion 3.5 Large Turbo** -- Faster variant, fewer inference steps needed.
- **Stable Diffusion 3.5 Medium** -- Smaller, faster, cheaper. Good quality at lower cost.
- **Stable Image Ultra** -- Stability's premium offering, highest fidelity output.
- **Stable Image Core** -- Fast, affordable general-purpose generation.

**API details:**
- Endpoint: `POST https://api.stability.ai/v2beta/stable-image/generate/<model-variant>` (e.g., `/sd3`, `/core`, `/ultra`)
- Auth: `Authorization: Bearer <api_key>` header
- Request: `multipart/form-data` with fields:
  - `prompt` (string, required)
  - `aspect_ratio` (string, e.g., `"16:9"`, `"1:1"`, `"4:3"` -- natively supported, no mapping needed)
  - `output_format` (string: `"png"`, `"jpeg"`, or `"webp"`)
  - `model` (string, for the `/sd3` endpoint: `"sd3.5-large"`, `"sd3.5-large-turbo"`, `"sd3.5-medium"`)
  - `negative_prompt` (string, optional)
- Response: When `Accept: image/*` header is set, returns raw image bytes directly. When `Accept: application/json` is set, returns `{ "image": "<base64>", "finish_reason": "SUCCESS" }`.
- Pricing: approximately $0.065/image for SD3.5 Large, $0.04/image for SD3.5 Large Turbo, $0.035/image for SD3.5 Medium, $0.008/image for Stable Image Core, $0.08/image for Stable Image Ultra. Credit-based billing.
- Rate limits: Vary by plan tier; returns HTTP 429.

**Note:** Stability AI natively supports aspect ratio strings (including `16:9`, `1:1`, `9:16`, `4:3`, `3:4`, `5:4`, `2:3`, `3:2`), which aligns well with our existing interface. This is the simplest provider to integrate from a parameter-mapping perspective.

**Outputs:**
- `app/services/stability_ai_provider.rb`
- `spec/services/stability_ai_provider_spec.rb`
- Registration in `ImageProviderRegistry`

**Acceptance criteria:**
- [ ] `StabilityAiProvider.new(api_key:, model: "sd3.5-large").generate(prompt:, aspect_ratio:)` returns `{ image_data:, mime_type: }`
- [ ] Supports model selection: `sd3.5-large`, `sd3.5-large-turbo`, `sd3.5-medium`, `core`, `ultra`
- [ ] Sends multipart/form-data requests with the correct content type
- [ ] Passes aspect ratio directly to the API (native support, no mapping needed)
- [ ] Requests JSON response format and extracts base64 image data
- [ ] Raises `RateLimitError` on HTTP 429, `ClientError` on 4xx (including 402 insufficient credits), `ServerError` on 5xx
- [ ] Registered in `ImageProviderRegistry` as `:stability_ai`
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

---

### Story F1.5: Ollama Local Image Generation Provider

**Description:** Build an `OllamaImageProvider` for local image generation via Ollama. This is the only provider that does not require an API key -- it runs on the user's own hardware, making it free (aside from compute cost) and fully private.

**Ollama image generation landscape:**

As of early 2025, Ollama's primary strength is running large language models locally, not image generation. Ollama does not have a dedicated image generation API endpoint in the way it has `/api/generate` for text or `/api/chat` for chat. However, there are paths to local image generation:

1. **Stable Diffusion via Ollama-adjacent tooling:** Ollama itself does not natively run diffusion-based image generation models (like Stable Diffusion or Flux). Image generation models have fundamentally different architectures (diffusion/flow-matching) than the transformer-based LLMs that Ollama runs. Users wanting local image generation typically use separate tools like ComfyUI, Automatic1111/Forge, or InvokeAI alongside Ollama.

2. **Multimodal LLMs with image output:** Some newer multimodal models can output images inline (similar to how Gemini does it). If Ollama adds support for models that can generate images as part of their output (e.g., models following the "any-to-any" paradigm), this provider could use the standard `/api/generate` or `/api/chat` endpoint and extract image data from the response. This is an emerging area to monitor.

3. **ComfyUI / Stable Diffusion WebUI as the actual backend:** The most practical approach for local image generation today is to integrate with ComfyUI's API or the Automatic1111/Forge API, both of which expose REST endpoints for Stable Diffusion and Flux model inference. These run locally just like Ollama does.

**Recommended approach:** Implement this provider to target **ComfyUI's API** as the local generation backend, since it is the most mature and widely-used local image generation server. Name the provider `LocalImageProvider` or `ComfyUiProvider` rather than `OllamaImageProvider` to accurately reflect the backend. If Ollama adds native image generation support in the future, a thin adapter can be added.

**ComfyUI API details:**
- Default endpoint: `http://127.0.0.1:8188`
- Workflow-based: You POST a workflow JSON to `/prompt`, which returns a `prompt_id`
- Poll `/history/<prompt_id>` for completion
- Retrieve generated images from `/view?filename=<output_filename>`
- Supports any model the user has installed locally (SD 1.5, SDXL, SD3, Flux Dev, Flux Schnell, etc.)

**Alternative if Ollama adds image generation:** Monitor Ollama's releases. If they add support for image generation models (e.g., via a new `/api/generate-image` endpoint or by supporting diffusion model architectures), add an `OllamaImageProvider` that hits:
- Endpoint: `POST http://localhost:11434/api/generate` (or equivalent new endpoint)
- Same localhost-first approach, user-configurable endpoint URL

**Outputs:**
- `app/services/local_image_provider.rb` (targeting ComfyUI API)
- `spec/services/local_image_provider_spec.rb`
- Registration in `ImageProviderRegistry` as `:local`

**Acceptance criteria:**
- [ ] `LocalImageProvider.new(endpoint: "http://127.0.0.1:8188", model: "flux-schnell").generate(prompt:, aspect_ratio:)` returns `{ image_data:, mime_type: }`
- [ ] Does not require an API key; authenticates via local network access only
- [ ] Endpoint URL is user-configurable (defaults to `http://127.0.0.1:8188`)
- [ ] Implements the ComfyUI workflow submission and polling flow
- [ ] Ships with default workflow templates for common models (SD3, SDXL, Flux Schnell)
- [ ] Maps aspect ratios to width/height pixel dimensions appropriate for the selected model
- [ ] Raises a clear connection error if the local server is not running
- [ ] Times out with a descriptive error if generation exceeds 300 seconds (local generation can be slow on CPU)
- [ ] Registered in `ImageProviderRegistry` as `:local`
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** Story F1.1

**Research notes / open questions:**
- [ ] Monitor Ollama releases for native image generation model support -- if added, build a dedicated `OllamaImageProvider` alongside this one
- [ ] Evaluate whether to also support Automatic1111/Forge WebUI API as an alternative local backend
- [ ] ComfyUI workflow JSON can be complex; consider shipping pre-built workflow templates and allowing advanced users to supply custom workflows
- [ ] Local generation speed varies dramatically by hardware (seconds on a 4090, minutes on CPU) -- need appropriate timeout handling and user expectations

---

### Story F1.6: Midjourney Provider (Investigation Only)

**Description:** Investigate Midjourney API availability and feasibility for integration. This story is research-only -- no implementation until the API situation is clarified.

**Current status (as of early 2025):**

Midjourney does **not** offer a public, generally-available REST API for image generation. The situation:

- **Discord-based usage:** Midjourney's primary interface is through Discord bot commands (`/imagine`). This is not suitable for programmatic integration -- it requires a Discord account, interacting via Discord's API (against Discord's ToS for automation in most cases), and parsing bot responses.
- **Midjourney Web App:** Midjourney launched a web interface at `midjourney.com` with generation capabilities, but this does not expose a documented public API.
- **Unofficial APIs / wrappers:** Third-party libraries exist that automate the Discord bot interaction, but these violate Midjourney's Terms of Service and are unreliable (subject to breaking changes and account bans).
- **Future API:** Midjourney has hinted at plans for a developer API but as of early 2025 has not shipped one publicly. They may offer an API in the future, potentially through partnerships or a dedicated developer program.

**Recommendation:** Do not build a Midjourney provider at this time. Revisit when/if Midjourney releases an official public API. The provider interface is designed to make adding new providers straightforward, so integration would be quick once an API is available.

**Acceptance criteria:**
- [ ] Document the current state of Midjourney API availability (this story serves as that documentation)
- [ ] Set up a monitoring reminder to check for Midjourney API announcements quarterly
- [ ] If an official API becomes available, create a follow-up story for `MidjourneyProvider` implementation
- [ ] Do NOT implement any integration based on unofficial Discord bot automation

**Dependencies:** None

---

### Story F1.7: Provider Selection UI & Settings

**Description:** Extend the Settings screen (Epic 3) to let users select their preferred image generation provider and configure provider-specific settings. Each provider has different configuration requirements:

| Provider | Required config |
|----------|----------------|
| Gemini (Nano Banana) | API key, model selection |
| OpenAI DALL-E | API key, model selection (dall-e-3 / gpt-image-1), quality tier |
| Flux (BFL) | API key, model selection (pro / dev / ultra) |
| Stability AI | API key, model selection (sd3.5-large / turbo / medium / core / ultra) |
| Local (ComfyUI) | Endpoint URL, model name, no API key |

**UI design:**
- A "Provider" section in Settings with a dropdown/radio group to select the active provider
- When a provider is selected, show its configuration fields dynamically (Stimulus controller)
- Provider-specific fields appear/disappear based on selection
- A "Test Connection" button that makes a lightweight API call to verify credentials work
- Visual indicator showing which provider is currently active
- Model selection dropdown populated per-provider with supported models

**Data model changes:**
- Add columns to `Setting`: `image_provider` (string, default: `"gemini"`), `image_provider_model` (string), `image_provider_api_key` (string, encrypted -- generic key field for the selected provider), `local_provider_endpoint` (string, default: `"http://127.0.0.1:8188"`), `image_quality` (string, default: `"standard"`)
- Alternatively, store provider config as a JSON column: `image_provider_config` (jsonb) -- but individual columns are simpler for encryption and validation

**Outputs:**
- Migration: `add_provider_fields_to_settings.rb`
- Updated `app/models/setting.rb` with new columns and encryption
- Updated `app/views/settings/show.html.erb` with provider selection UI
- `app/javascript/controllers/provider_settings_controller.js` (Stimulus controller for dynamic fields)
- Updated `app/controllers/settings_controller.rb` with permitted params and test-connection action
- `spec/system/settings_provider_selection_spec.rb`

**Acceptance criteria:**
- [ ] Settings page has a "Provider" section with radio buttons or a dropdown for each registered provider
- [ ] Selecting a provider dynamically shows/hides the relevant configuration fields
- [ ] API key fields display masked when a key is already stored (consistent with existing behavior)
- [ ] "Test Connection" button makes a lightweight call and shows success/failure feedback
- [ ] The local provider section shows an endpoint URL field instead of an API key field
- [ ] Each provider has a model selection dropdown with its supported models
- [ ] Saving settings persists the selected provider and its configuration
- [ ] The generation pipeline (`VisionGenerationJob`) uses `Setting.current.image_provider` to resolve the correct provider class via the registry
- [ ] Existing users default to Gemini with no disruption
- [ ] Tests pass (unit + system)

**Dependencies:** Story F1.1, at least one additional provider (F1.2, F1.3, F1.4, or F1.5)

---

## Provider Comparison Summary

| Provider | Type | Approx. Cost/Image | Aspect Ratio Support | API Style | Auth |
|----------|------|--------------------|-----------------------|-----------|------|
| Gemini (current) | Cloud | ~$0.04 | Native string (`"16:9"`) | Synchronous POST | API key in query param |
| OpenAI GPT Image 1 | Cloud | $0.01--$0.17 (varies by quality/size) | Map to fixed sizes | Synchronous POST | Bearer token header |
| OpenAI DALL-E 3 | Cloud | $0.04--$0.12 (varies by size/quality) | Map to fixed sizes | Synchronous POST | Bearer token header |
| Flux (BFL) | Cloud | $0.025--$0.06 | Map to width/height pixels | Async (submit + poll) | `X-Key` header |
| Stability AI | Cloud | $0.008--$0.08 (varies by model) | Native string (`"16:9"`) | Synchronous POST (multipart) | Bearer token header |
| Local (ComfyUI) | Local | Free (user hardware) | Map to width/height pixels | Async (submit + poll) | None (local network) |
| Midjourney | Cloud | N/A | N/A | No public API available | N/A |

## Implementation Order

1. **Story F1.1** -- Provider interface extraction and registry (foundation for everything else)
2. **Story F1.4** -- Stability AI provider (simplest integration -- native aspect ratio support, synchronous API, multipart is straightforward with Faraday)
3. **Story F1.2** -- OpenAI DALL-E provider (synchronous API, well-documented, widely used)
4. **Story F1.3** -- Flux BFL provider (async polling adds complexity but Flux quality is excellent)
5. **Story F1.5** -- Local provider via ComfyUI (most complex -- workflow JSON, local server dependency, variable hardware performance)
6. **Story F1.7** -- Provider selection UI (needs at least 2 providers to be meaningful)
7. **Story F1.6** -- Midjourney investigation (ongoing monitoring, no implementation)

## Risks & Open Questions

- **API changes:** Cloud provider APIs evolve frequently. Pricing, endpoints, and model names may change. Each provider should centralize endpoint URLs and model names as constants for easy updates.
- **Aspect ratio fidelity:** Providers that require fixed pixel dimensions (OpenAI, Flux, ComfyUI) may not perfectly match the requested aspect ratio. Document the mapping and accept minor deviations.
- **Async provider complexity:** Flux and ComfyUI both use async submit-and-poll patterns. This adds complexity (polling intervals, timeouts, orphaned tasks) compared to synchronous providers. Consider extracting a shared async polling concern.
- **Local provider UX:** Users need to install and run ComfyUI separately. The settings UI should link to setup instructions and clearly indicate when the local server is unreachable.
- **Cost visibility:** Different providers have very different pricing. Consider surfacing estimated cost-per-image in the provider selection UI so users can make informed choices. (Related: future "Cost Tracking" idea in `docs/epics/future-ideas.md`.)
- **Image format consistency:** Providers return different formats (PNG, JPEG, WebP). The provider interface returns `mime_type` to handle this, but downstream code (Active Storage attachment, thumbnail rendering) must handle all formats gracefully.
