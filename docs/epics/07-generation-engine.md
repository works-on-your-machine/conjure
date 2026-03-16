# Epic: Generation Engine & Background Jobs

**Status:** Ready
**Phase:** 3 — Generation Pipeline
**Depends on:** Data Model, Settings
**Blocks:** Visions Wall

## Goal

Wire up the full generation pipeline: prompt assembly via LLM, image generation via Nano Banana 2, background job orchestration via Solid Queue, and real-time progress updates via Turbo Streams. After this epic, hitting "Conjure" creates visions.

## Scope

**In scope:**
- GenerationService with provider abstraction
- NanoBanana2Provider for image generation API calls
- LLM prompt assembly service (merging grimoire_text + slide_text into an image generation prompt)
- ConjuringJob: Solid Queue job that orchestrates the full pipeline
- Turbo Stream broadcasts as each vision is generated
- Conjuring status transitions (pending → generating → complete/failed)
- Error handling for API failures

**Out of scope:**
- The Visions Wall UI (next epic — this epic creates the data, that epic displays it)
- Refinement prompt handling (deferred to Final Cut epic)
- Cost tracking (v0.2)
- Multiple LLM provider support (start with one, abstract later)

## Stories

### Story 7.1: GenerationService & Image Provider

**Description:** Create the GenerationService with a provider interface and a NanoBanana2Provider that calls the Nano Banana 2 API. The provider takes a prompt string and count, returns image data. Use Faraday for HTTP calls. API key comes from Setting.current.

**Inputs:**
- Design doc Generation Service section (lines 293–311)
- `app/models/setting.rb` for API keys

**Outputs:**
- `app/services/generation_service.rb`
- `app/services/nano_banana2_provider.rb`
- `test/services/generation_service_test.rb` (with stubbed HTTP)
- `test/services/nano_banana2_provider_test.rb`

**Acceptance criteria:**
- [ ] `GenerationService.new.generate(prompt, count: 5)` returns an array of image data/URLs
- [ ] NanoBanana2Provider makes HTTP POST to the Nano Banana 2 API with the correct payload
- [ ] API key is read from `Setting.current.nano_banana_api_key`
- [ ] Handles API errors gracefully (returns error info, doesn't crash)
- [ ] Tests pass with stubbed HTTP responses

**Dependencies:** None (within this epic)

---

### Story 7.2: Prompt Assembly Service

**Description:** Create a service that takes grimoire_text and slide_text (and optional refinement) and uses an LLM to assemble an effective image generation prompt. The LLM merges the theme description with the slide content into a prompt optimized for image generation. Store the assembled prompt as vision.prompt.

**Inputs:**
- Design doc Prompt Assembly section (lines 246–280)
- `app/models/setting.rb` for LLM API key

**Outputs:**
- `app/services/prompt_assembly_service.rb`
- `test/services/prompt_assembly_service_test.rb` (with stubbed LLM response)

**Acceptance criteria:**
- [ ] `PromptAssemblyService.new.assemble(grimoire_text:, slide_text:)` returns a prompt string
- [ ] Optionally accepts `refinement:` parameter that gets folded into the prompt
- [ ] Uses the LLM API key from Setting.current
- [ ] Returns a usable prompt even if the LLM call fails (fallback: concatenation of grimoire_text + slide_text)
- [ ] Tests pass with stubbed LLM responses

**Dependencies:** None (within this epic)

---

### Story 7.3: ConjuringJob — Background Generation Pipeline

**Description:** Create the Solid Queue job that orchestrates a full conjuring run. When enqueued, it: (1) sets conjuring status to generating, (2) for each slide in scope, assembles a prompt via PromptAssemblyService, (3) generates N images via GenerationService, (4) creates Vision records with attached images, (5) sets conjuring status to complete (or failed on error).

**Inputs:**
- Design doc Generation Pipeline (lines 225–289)
- `app/models/conjuring.rb`, `app/models/vision.rb`
- Services from Stories 7.1 and 7.2

**Outputs:**
- `app/jobs/conjuring_job.rb`
- `test/jobs/conjuring_job_test.rb`

**Acceptance criteria:**
- [ ] `ConjuringJob.perform_later(conjuring)` processes the conjuring asynchronously
- [ ] Conjuring status transitions: pending → generating → complete
- [ ] For each slide in the conjuring's project, N visions are created (N = conjuring.variations_count)
- [ ] Each vision has: slide_text (frozen copy), prompt (from assembly), attached image, position
- [ ] Conjuring grimoire_text is frozen at creation time and passed through to prompt assembly
- [ ] On API failure, conjuring status is set to :failed
- [ ] Tests pass (with stubbed services)

**Dependencies:** Stories 7.1, 7.2

---

### Story 7.4: Turbo Stream Progress Broadcasts

**Description:** Add Turbo Stream broadcasts to the ConjuringJob so the browser updates in real time as visions are generated. Each time a vision is created, broadcast a Turbo Stream append to the project's vision wall. Also broadcast conjuring status changes.

**Inputs:**
- `app/jobs/conjuring_job.rb` from Story 7.3
- `app/models/conjuring.rb`, `app/models/vision.rb`
- Action Cable / Solid Cable configuration

**Outputs:**
- Turbo Stream broadcasts in ConjuringJob (after each vision creation)
- `app/models/conjuring.rb` — broadcasts_to or after_update_commit for status changes
- `app/views/visions/_vision.html.erb` (partial for a single vision thumbnail — needed for the broadcast target)

**Acceptance criteria:**
- [ ] When a vision is created during a conjuring, a Turbo Stream append is broadcast
- [ ] When conjuring status changes, a Turbo Stream replace is broadcast
- [ ] Broadcasts target a channel scoped to the project (e.g., `project_#{id}_visions`)
- [ ] The vision partial renders a thumbnail image with basic metadata
- [ ] No N+1 queries in the broadcast rendering

**Dependencies:** Story 7.3

---

## Implementation Order

1. **Story 7.1** — Image generation provider is the foundation
2. **Story 7.2** — Prompt assembly is independent and can be built in parallel with 7.1
3. **Story 7.3** — The job ties everything together; needs both services
4. **Story 7.4** — Real-time updates layer on top of the working job
