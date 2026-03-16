# Epic: Generation Engine & Background Jobs

**Status:** Ready
**Phase:** 3 — Generation Pipeline
**Depends on:** Data Model, Settings
**Blocks:** Visions Wall

## Goal

Wire up the full generation pipeline: prompt assembly via LLM, image generation via Gemini (Nano Banana), two-tier background job orchestration via Solid Queue with parallel generation, and real-time progress updates via Turbo Streams. After this epic, hitting "Conjure" creates visions.

## Scope

**In scope:**
- GeminiImageProvider for Gemini API image generation calls
- LLM prompt assembly service (merging grimoire_text + slide_text into an image generation prompt)
- Two-tier job architecture: ConjuringJob (orchestrator) → VisionGenerationJob (per-vision worker)
- Parallel vision generation via Solid Queue concurrency
- Retry with exponential backoff for rate limits (HTTP 429) and server errors (5xx)
- Vision status tracking (pending → generating → complete → failed)
- Turbo Stream broadcasts as each vision completes
- Conjuring status transitions (pending → generating → complete/failed)

**Out of scope:**
- The Visions Wall UI (next epic — this epic creates the data, that epic displays it)
- Refinement prompt handling (deferred to Final Cut epic)
- Cost tracking (v0.2)
- Reference image for style consistency (see `docs/epics/future-ideas.md`)
- Batch API support (see `docs/epics/future-ideas.md`)

## API Details

**Gemini Image Generation:**
- Endpoint: `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
- Model: `gemini-2.5-flash-image` (cheapest at ~$0.04/image)
- Request: `generationConfig.responseModalities: ["TEXT", "IMAGE"]`, with `imageConfig.aspectRatio`
- Response: Base64 PNG in `inline_data` with `mime_type: "image/png"`
- One image per request — hence the per-vision job architecture
- Rate limits: IPM (images per minute), varies by tier. Handle 429 with exponential backoff.

## Stories

### Story 7.1: GeminiImageProvider & Vision Status Migration

**Description:** Create the Gemini image provider that calls the Gemini API to generate a single image from a prompt. Add a `status` column to Vision (pending/generating/complete/failed) for per-vision tracking. Use Faraday for HTTP calls. API key comes from Setting.current.

**Inputs:**
- Gemini API docs: https://ai.google.dev/gemini-api/docs/image-generation
- `app/models/setting.rb` for API key (`nano_banana_api_key`)

**Outputs:**
- `app/services/gemini_image_provider.rb`
- `db/migrate/..._add_status_to_visions.rb`
- `spec/services/gemini_image_provider_spec.rb` (with stubbed HTTP)

**Acceptance criteria:**
- [x] `GeminiImageProvider.new(api_key:).generate(prompt:, aspect_ratio:)` returns `{ image_data: <base64>, mime_type: "image/png" }`
- [x] Makes correct POST to Gemini `generateContent` endpoint with `responseModalities: ["IMAGE"]`
- [x] Raises specific errors for 429 (rate limit), 4xx (client error), 5xx (server error)
- [x] Vision model has status enum: `{ pending: 0, generating: 1, complete: 2, failed: 3 }`
- [x] Tests pass with stubbed HTTP responses

**Dependencies:** None (within this epic)

---

### Story 7.2: Prompt Assembly Service

**Description:** Create a service that takes grimoire_text and slide_text (and optional refinement) and uses an LLM to assemble an effective image generation prompt. The LLM merges the theme description with the slide content into a prompt optimized for Gemini image generation. Store the assembled prompt as vision.prompt.

**Inputs:**
- Design doc Prompt Assembly section (lines 246–280)
- `app/models/setting.rb` for LLM API key

**Outputs:**
- `app/services/prompt_assembly_service.rb`
- `spec/services/prompt_assembly_service_spec.rb` (with stubbed LLM response)

**Acceptance criteria:**
- [x] `PromptAssemblyService.new.assemble(grimoire_text:, slide_text:)` returns a prompt string
- [x] Optionally accepts `refinement:` parameter that gets folded into the prompt
- [x] Uses the LLM API key from Setting.current
- [x] Returns a usable prompt even if the LLM call fails (fallback: concatenation of grimoire_text + slide_text)
- [x] Tests pass with stubbed LLM responses

**Dependencies:** None (within this epic)

---

### Story 7.3: ConjuringJob & VisionGenerationJob — Two-Tier Pipeline

**Description:** Create two Solid Queue jobs:

1. **ConjuringJob** (orchestrator): Sets conjuring to `generating`, creates Vision records (status: pending) for each slide × variation, assembles prompts via PromptAssemblyService, enqueues a VisionGenerationJob for each vision.
2. **VisionGenerationJob** (worker): Takes a single vision, calls GeminiImageProvider to generate the image, attaches it via Active Storage, sets vision status to complete. On failure, sets vision status to failed.

After all VisionGenerationJobs complete, a callback or check sets the conjuring to complete (or failed if all visions failed).

**Inputs:**
- Design doc Generation Pipeline (lines 225–289)
- `app/models/conjuring.rb`, `app/models/vision.rb`
- Services from Stories 7.1 and 7.2

**Outputs:**
- `app/jobs/conjuring_job.rb`
- `app/jobs/vision_generation_job.rb`
- `spec/jobs/conjuring_job_spec.rb`
- `spec/jobs/vision_generation_job_spec.rb`

**Acceptance criteria:**
- [x] `ConjuringJob.perform_later(conjuring)` creates vision records and enqueues VisionGenerationJobs
- [x] Conjuring status transitions: pending → generating → complete
- [x] VisionGenerationJob generates one image, attaches it, sets vision status to complete
- [x] VisionGenerationJob retries on HTTP 429 (rate limit) with exponential backoff, up to 5 attempts
- [x] VisionGenerationJob retries on HTTP 5xx (server error) with backoff, up to 3 attempts
- [x] VisionGenerationJob does NOT retry on HTTP 4xx (client error) — marks vision as failed immediately
- [x] Each vision has: slide_text (frozen copy), prompt (from assembly), attached image, position, status
- [x] Conjuring.grimoire_text is frozen at creation time and passed through to prompt assembly
- [x] When all visions for a conjuring are complete/failed, conjuring status is set to complete (or failed if all failed)
- [x] Tests pass (with stubbed services)

**Dependencies:** Stories 7.1, 7.2

---

### Story 7.4: Turbo Stream Progress Broadcasts

**Description:** Add Turbo Stream broadcasts so the browser updates in real-time as visions are generated. Each time a VisionGenerationJob completes, broadcast a Turbo Stream append to the project's vision wall. Also broadcast conjuring status changes.

**Inputs:**
- `app/jobs/vision_generation_job.rb` from Story 7.3
- `app/models/conjuring.rb`, `app/models/vision.rb`
- Action Cable / Solid Cable configuration

**Outputs:**
- Turbo Stream broadcasts in VisionGenerationJob (after each vision completion)
- `app/models/conjuring.rb` — broadcasts_to or after_update_commit for status changes
- `app/views/visions/_vision.html.erb` (partial for a single vision thumbnail — needed for the broadcast target)

**Acceptance criteria:**
- [x] When a vision completes generation, a Turbo Stream append is broadcast
- [x] When conjuring status changes, a Turbo Stream replace is broadcast
- [x] Broadcasts target a channel scoped to the project (e.g., `project_#{id}_visions`)
- [x] The vision partial renders a thumbnail image with basic metadata
- [x] No N+1 queries in the broadcast rendering

**Dependencies:** Story 7.3

---

## Implementation Order

1. **Story 7.1** — Gemini provider + Vision status migration are the foundation
2. **Story 7.2** — Prompt assembly is independent and can be built in parallel with 7.1
3. **Story 7.3** — The two-tier job pipeline ties everything together; needs both services
4. **Story 7.4** — Real-time updates layer on top of the working jobs
