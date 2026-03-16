# Epic: Final Cut & Refinement

**Status:** Ready
**Phase:** 4 — Assembly & Export
**Depends on:** Visions Wall
**Blocks:** Export

## Goal

Build the Final Cut section where users review their curated deck in presentation order and refine individual slides through prompt-based re-generation.

## Scope

**In scope:**
- Assembly view showing selected visions in slide order
- Placeholder display for slides without a selected vision
- Refine modal: text prompt input that creates a new conjuring scoped to one slide
- Navigation between Final Cut and Visions sections

**Out of scope:**
- Export functionality (separate epic)
- Drag-and-drop reordering of the final cut (slide order comes from Incantations)

## Stories

### Story 9.1: Assembly View

**Description:** Create the Final Cut section within the project workspace. Display the selected vision for each slide in presentation order (by slide position). Slides without a selected vision show as dashed placeholders with a prompt to "Select a vision" linking to the wall. Show slide number and title alongside each vision.

**Inputs:**
- Design doc Final Cut section (lines 626–644)
- React prototype `docs/conjure-app-mockup.jsx` — Assembly view (line 406): max-width 900px centered. Header with "Final cut" title, selection count, "← Visions" back button, "Export to Figma" button, and "Export PDF" gold button (disabled when not all slides selected). Each slide row is a flex layout: slide number (32px, right-aligned), vision image (flex:1), and slide info column (140px) with title + variation number. Unselected slides show dashed 16:9 placeholder with "No vision — {title}" text. "✦ Refine" button overlays bottom-right of each vision with backdrop blur.
- `app/models/slide.rb`, `app/models/vision.rb`
- Project workspace from Epic 5

**Outputs:**
- Final Cut view (partial or dedicated route within project workspace)
- `app/views/final_cuts/_slide_preview.html.erb`
- Navigation link to visions wall for unselected slides

**Acceptance criteria:**
- [x] Final Cut shows one vision per slide in presentation order
- [x] Each entry shows slide number, title, and the selected vision's image
- [x] Slides without a selected vision show a dashed placeholder with "Select a vision" link
- [x] "Refine" button appears on each slide that has a selected vision
- [x] Clear count of selected vs. total slides (e.g., "6/8 slides ready")
- [x] Tests pass

**Dependencies:** None (within this epic)

---

### Story 9.2: Refine Modal

**Description:** Build the refinement modal that lets users re-conjure a single slide with additional prompt instructions. The modal shows the current selected vision, a text input for refinement instructions, and a "Re-conjure with changes" button. This creates a new Conjuring scoped to just that one slide, with the refinement text stored in `vision.refinement`.

**Inputs:**
- Design doc Refine modal (lines 630–643) and Refinement Boundary (lines 666–682)
- React prototype `docs/conjure-app-mockup.jsx` — Refine modal (line 460): fixed overlay with 600px modal. Shows "Refine: {slide title}" header, current vision image, "Describe your refinement" label, textarea (3 rows) with placeholder examples, Cancel + "✦ Re-conjure with changes" gold button, and Figma export note at bottom in textDim.
- `app/models/conjuring.rb`, `app/models/vision.rb`
- `app/jobs/conjuring_job.rb` from Epic 7
- PromptAssemblyService from Epic 7

**Outputs:**
- Refine modal view (Turbo Frame or stimulus-driven modal)
- Controller action to create a refinement conjuring
- Updated ConjuringJob to handle single-slide refinement scope

**Acceptance criteria:**
- [x] Clicking "Refine" opens a modal showing the current selected vision
- [x] Modal has a text input with placeholder examples ("Make the headline text larger", "Add more VHS static texture")
- [x] "Re-conjure with changes" creates a new Conjuring scoped to just that slide
- [x] The refinement text is stored in `vision.refinement` on the resulting visions
- [x] PromptAssemblyService receives the refinement parameter
- [x] Original vision is preserved; new refined visions appear in the wall alongside it
- [x] Note at bottom: "For compositing, use Export to Figma for pixel-level control"
- [x] Tests pass

**Dependencies:** Story 9.1

---

## Implementation Order

1. **Story 9.1** — Assembly view is the container; refine builds on top of it
2. **Story 9.2** — Refinement is the key interactive feature of this section
