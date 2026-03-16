# Epic: Visions Wall

**Status:** Ready
**Phase:** 3 — Generation Pipeline
**Depends on:** Generation Engine, Incantations
**Blocks:** Final Cut

## Goal

Build the Visions section — the core product experience. A wall of all generated visions organized by slide, with gold glow selection, conjuring scope controls, provenance panel, and the Conjure button that kicks off generation.

## Scope

**In scope:**
- Vision wall layout: slides as rows, visions as scrollable thumbnails per row
- Gold glow selection toggle with ✦ indicator (Stimulus controller)
- Conjuring badges showing which run produced each vision
- Conjure button with scope controls (all slides / selected slides / slides without visions)
- Cost estimate display (slides × variations × cost per image)
- Provenance panel: click a vision to see grimoire_text, slide_text, prompt, refinement
- Delete individual visions and bulk delete by conjuring
- Real-time updates from Turbo Stream broadcasts (wired in Epic 7)

**Out of scope:**
- Filtering by conjuring / date range / selected (v0.2)
- "Generate more like this" / "Generate more different" (v0.2)
- Disk usage indicator on this page (covered in Settings)

## Stories

### Story 8.1: Vision Wall Layout & Conjure Button

**Description:** Create the visions section view within the project workspace. Display all slides as rows, each with a horizontally scrollable row of vision thumbnails. Add the Conjure button that creates a new Conjuring record and enqueues the ConjuringJob. Include scope controls (conjure all / selected slides / slides without visions).

**Inputs:**
- Design doc Visions Section (lines 587–624)
- React prototype `docs/conjure-app-mockup.jsx` — Visions wall (line 377): header with "Visions" title + grimoire name + selection count ("X/Y selected"), "View assembly" gold button when selections exist. Each slide is a row with gold title, selection status text, and a CSS grid of variations (`repeat(N, 1fr)` where N = variation count). Generating state (line 398): centered spinner with "Summoning N visions..." text. The `Variation` component (line 59) defines the thumbnail: 16:9 aspect ratio, gradient background, gold border + shadow + scale(1.02) + ✦ badge on selection.
- `app/models/vision.rb`, `app/models/conjuring.rb`, `app/models/slide.rb`
- `app/jobs/conjuring_job.rb` from Epic 7
- Project workspace from Epic 5

**Outputs:**
- `app/controllers/conjurings_controller.rb` (create action — kicks off generation)
- `app/views/visions/index.html.erb` or project visions partial
- `app/views/visions/_slide_row.html.erb` (slide title + vision thumbnails)
- `app/views/visions/_vision.html.erb` (single vision thumbnail)
- Routes for conjurings#create nested under projects
- `test/controllers/conjurings_controller_test.rb`

**Acceptance criteria:**
- [x] Visions section shows each slide as a labeled row
- [x] Each row shows vision thumbnails in a horizontally scrollable container
- [x] Visions are grouped by conjuring, most recent first
- [x] Each vision shows a conjuring badge (e.g., "Run 1", "Run 2")
- [x] Conjure button creates a Conjuring record with frozen grimoire_text and enqueues ConjuringJob
- [x] Scope selector lets user choose: all slides, selected slides only, slides without visions
- [x] New visions appear in real time via Turbo Stream (from Epic 7)
- [x] Tests pass

**Dependencies:** None (within this epic)

---

### Story 8.2: Vision Selection with Gold Glow

**Description:** Implement the gold glow selection state for visions. Clicking a vision toggles its `selected` boolean. The selected state renders as a gold border + shadow + ✦ indicator. Use a Stimulus controller for the client-side toggle and a PATCH request to persist the selection.

**Inputs:**
- Design doc selection indicator (lines 30–31, 594–595)
- React prototype `docs/conjure-app-mockup.jsx` — `Variation` component (line 59): selected state has `2px solid #c4935a` border, `boxShadow: 0 0 24px rgba(196,147,90,0.3)`, `transform: scale(1.02)`. The ✦ badge is a 20px gold circle positioned absolute top-right with 11px white text. Unselected has `1px solid rgba(255,255,255,0.06)` border.
- Shared gold glow styles from Epic 2
- `app/models/vision.rb`

**Outputs:**
- `app/javascript/controllers/vision_selection_controller.js` (Stimulus)
- `app/controllers/visions_controller.rb` (update action for toggling selection)
- Routes: `resources :visions, only: [:update]` nested under projects
- Updated vision thumbnail partial with selection state

**Acceptance criteria:**
- [x] Clicking a vision thumbnail toggles the gold glow on/off
- [x] Gold glow: warm gold border, shadow, and ✦ symbol overlay
- [x] Toggle persists to the database (vision.selected = true/false)
- [x] Multiple visions per slide can be selected (but typically one per slide for final cut)
- [x] Selection count is displayed (e.g., "6/8 slides have a selected vision")
- [x] Tests pass

**Dependencies:** Story 8.1

---

### Story 8.3: Cost Estimate Display

**Description:** Add a live cost estimate near the Conjure button. The estimate calculates: (slides in scope) × (variation count) × (cost per image, e.g. $0.08). It should update as the user changes scope or variation count. Use a Stimulus controller to compute this client-side.

**Inputs:**
- Design doc cost estimate (lines 454, 560, 728)
- Conjure button and scope controls from Story 8.1

**Outputs:**
- `app/javascript/controllers/cost_estimate_controller.js` (Stimulus)
- Cost estimate display element near the Conjure button

**Acceptance criteria:**
- [x] Cost estimate displays below/beside the Conjure button
- [x] Estimate updates when scope changes (all slides vs. subset)
- [x] Estimate updates when variation count changes
- [x] Format: "~$3.20 (8 slides × 5 variations × $0.04)"
- [x] Shows $0.00 when no slides are in scope

**Dependencies:** Story 8.1

---

### Story 8.4: Provenance Panel

**Description:** Clicking a vision thumbnail opens a detail/provenance panel showing exactly what inputs produced it: the conjuring's grimoire_text, the vision's slide_text, the assembled prompt, and any refinement. Use a Turbo Frame or modal.

**Inputs:**
- Design doc Provenance section (lines 197–204, 603–609)
- `app/models/vision.rb`, `app/models/conjuring.rb`

**Outputs:**
- `app/views/visions/show.html.erb` or `_provenance.html.erb` partial
- `app/controllers/visions_controller.rb` (show action)
- Route for visions#show

**Acceptance criteria:**
- [x] Clicking a vision opens a detail panel/modal
- [x] Panel shows: conjuring run number and timestamp, grimoire_text, slide_text, assembled prompt, refinement (if any)
- [x] Panel shows the full-size image
- [x] Closeable — returns to the wall view
- [x] Tests pass

**Dependencies:** Story 8.1

---

### Story 8.5: Vision Deletion

**Description:** Add delete actions for individual visions and bulk delete by conjuring. Individual delete removes one vision and its attached image. Bulk delete removes all visions from a specific conjuring.

**Inputs:**
- `app/models/vision.rb`, `app/models/conjuring.rb`
- Vision wall from Story 8.1

**Outputs:**
- Delete button on individual visions (in provenance panel or on hover)
- "Delete all from this run" action on conjuring badges
- `app/controllers/visions_controller.rb` (destroy action)
- `app/controllers/conjurings_controller.rb` (destroy action)

**Acceptance criteria:**
- [x] Individual vision delete removes the vision and its Active Storage image
- [x] Bulk conjuring delete removes all visions from that conjuring
- [x] Both actions require confirmation
- [x] Wall updates after deletion (removed visions disappear)
- [x] Tests pass

**Dependencies:** Stories 8.1, 8.4

---

## Implementation Order

1. **Story 8.1** — Wall layout and Conjure button are the foundation
2. **Story 8.2** — Selection is the core interaction; needed before cost estimate makes sense
3. **Story 8.3** — Cost estimate builds on the scope controls from 8.1
4. **Story 8.4** — Provenance panel is a detail view on top of the working wall
5. **Story 8.5** — Deletion is a management action, lowest risk to defer
