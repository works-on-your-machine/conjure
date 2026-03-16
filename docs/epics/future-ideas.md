# Future Ideas & Investigation Items

Ideas and experiments that came up during v0.1 development. Not committed to any release — these need investigation and validation first.

---

### Reference Image for Style Consistency

**Idea:** Include a reference image in the Gemini image generation call to enforce visual style consistency across slides. Gemini supports up to 14 reference images per request.

**How it could work:**
- When a grimoire is first used, generate a single "style reference" image from the grimoire description
- Include that reference image in every subsequent vision generation call for that grimoire
- Could also let users upload their own reference images to a grimoire
- Could include the previously selected vision for a slide when doing refinement (so "make the headline bigger" has visual context)

**Why this matters:** Currently, each slide is generated independently — the only style consistency comes from the text prompt (grimoire_text + slide_text). Including a visual reference would make the generated slides feel more cohesive as a deck.

**Needs investigation:**
- [ ] Does including a reference image actually improve style consistency in practice?
- [ ] What resolution should the reference image be? (cost implications — larger = more tokens)
- [ ] Does it work well with refinement prompts? (include the current vision as reference + refinement text)
- [ ] Performance impact — does adding an image to the request significantly slow generation?
- [ ] Cost impact — reference images consume input tokens

**Related Gemini docs:** The API supports `inlineData` parts with images in the `contents` array alongside text prompts. Up to 14 reference images per request.

---

### Batch API for High-Volume Generation

**Idea:** Use Gemini's Batch API for conjurings with many visions (e.g., 20 variations × 8 slides = 160 images). Batch API offers 50% cost savings and better rate limits.

**Tradeoff:** Batch API doesn't return results in real-time — no per-vision Turbo Stream updates. Could offer this as a "budget mode" option.

---

### Cost Tracking per Conjuring

Already in v0.2 scope. Track actual spend per conjuring based on model + resolution used, display cumulative cost per project.
