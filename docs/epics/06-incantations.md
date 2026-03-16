# Epic: Incantations (Slide Editor)

**Status:** Ready
**Phase:** 2 — Content Management
**Depends on:** Workshop & Project Management
**Blocks:** Visions Wall

## Goal

Build the Incantations section where users create, edit, and reorder their slide descriptions — the inputs that drive image generation.

## Scope

**In scope:**
- Split-pane view: slide list on left, editor on right
- Slide CRUD: add, edit, remove
- Slide reordering (move up/down)
- Turbo Frame for editor pane (selecting a slide loads its editor without full page reload)

**Out of scope:**
- AI assists: "Generate from outline", "Expand description", "Suggest visual approach" (all v0.2)
- Drag-and-drop reordering (move up/down buttons are sufficient for v0.1)

## Stories

### Story 6.1: Slides Controller & Split-Pane View

**Description:** Create a slides controller nested under projects. The incantations section shows a split-pane layout: slide list on the left with titles and description previews, and a slide editor on the right. Use Turbo Frames so clicking a slide in the list loads its editor without a full page reload.

**Inputs:**
- `app/models/slide.rb`, `app/models/project.rb` from Epic 1
- Design doc Incantations section (lines 563–586)
- React prototype `docs/conjure-app-mockup.jsx` — Incantations view (line 336): full-height flex with left pane (260px, border-right) containing slide list and right pane (flex:1) containing editor. Left pane: "Incantations" header with slide count, slide items with goldGlow active state showing title + description preview (ellipsis overflow), "Add slide" input+button at bottom, "Generate from outline" ghost button. Right pane: inline-editable title in serif/22px, "What this slide should show" label, description textarea (10 rows), AI assist ghost buttons, Move up/Move down/Remove buttons. Outline modal (line 439): fixed overlay, 600px modal with textarea and "Generate slides" gold button.
- Project workspace layout from Epic 5

**Outputs:**
- `app/controllers/slides_controller.rb` (index, new, create, edit, update, destroy)
- `app/views/slides/index.html.erb` or partial for incantations section
- `app/views/slides/_slide_list.html.erb` (left pane)
- `app/views/slides/_form.html.erb` (right pane editor)
- Routes: `resources :projects do resources :slides end`
- `test/controllers/slides_controller_test.rb`

**Acceptance criteria:**
- [x] Incantations section shows split-pane: slide list left, editor right
- [x] Slide list shows all slides with title and description preview, ordered by position
- [x] Clicking a slide in the list loads its editor in the right pane via Turbo Frame
- [x] Editor shows editable title (text input) and description (textarea)
- [x] Saving a slide updates it and refreshes the list entry
- [x] Tests pass

**Dependencies:** None (within this epic)

---

### Story 6.2: Add, Remove, and Reorder Slides

**Description:** Add the ability to create new slides, remove existing ones, and reorder with move up/down buttons. New slide needs a title input. Remove needs confirmation. Reorder swaps positions with adjacent slides.

**Inputs:**
- Slides controller from Story 6.1
- `app/models/slide.rb` with position column

**Outputs:**
- "Add slide" form at bottom of slide list (title input + button)
- Delete button on each slide in the editor
- Move up / Move down buttons on each slide
- Position management logic in controller or model

**Acceptance criteria:**
- [x] "Add slide" creates a new slide at the end of the list with the given title
- [x] New slide appears in the list immediately (Turbo Stream or Frame refresh)
- [x] "Remove" deletes the slide after confirmation, updates the list
- [x] "Move up" swaps position with the slide above, "Move down" with the slide below
- [x] First slide has no "Move up", last slide has no "Move down"
- [x] Positions remain contiguous after add/remove/reorder operations
- [x] Tests pass

**Dependencies:** Story 6.1

---

## Implementation Order

1. **Story 6.1** — The split-pane layout and basic editing must exist first
2. **Story 6.2** — Add/remove/reorder builds on the working list and editor
