# Epic: Export

**Status:** Ready
**Phase:** 4 — Assembly & Export
**Depends on:** Final Cut
**Blocks:** Nothing

## Goal

Let users export their curated presentation as PDF, PNG folder (for Figma), or a full project zip with conjuring history for backup/sharing.

## Scope

**In scope:**
- PDF export of selected visions in slide order
- PNG folder export (individual slide images for Figma import)
- Project zip export (all visions, conjuring history, grimoire texts, slide descriptions)
- Export buttons on the Final Cut section

**Out of scope:**
- Direct Figma API integration (PNG folder is the bridge)
- Keynote/Google Slides export (v0.3)
- Speaker notes generation (v0.3)

## Stories

### Story 10.1: PDF Export

**Description:** Add a PDF export that assembles the selected visions into a PDF in slide order. Use MiniMagick or Prawn (per design doc) to combine the images into a multi-page PDF. Each page is one slide's selected vision at the project's aspect ratio.

**Inputs:**
- Design doc Export section (lines 479–492, 726–727)
- `app/models/project.rb`, `app/models/vision.rb` (selected visions)
- Gemfile — may need to add `prawn` or `mini_magick` gem

**Outputs:**
- `app/services/pdf_export_service.rb`
- Export controller action or route
- "Export PDF" button on Final Cut view
- `test/services/pdf_export_service_test.rb`

**Acceptance criteria:**
- [x] "Export PDF" downloads a PDF file
- [x] PDF contains one page per slide with the selected vision's image
- [x] Pages are in slide position order
- [x] PDF file name includes the project name (e.g., "my-presentation.pdf")
- [x] Export is disabled or warns when not all slides have a selected vision
- [x] Tests pass

**Dependencies:** None (within this epic)

---

### Story 10.2: PNG Folder Export (Figma)

**Description:** Export selected visions as a folder of individually named PNG files inside a zip. File names follow a pattern like `01-slide-title.png`. This is the escape hatch for pixel-level work in Figma.

**Inputs:**
- `app/models/vision.rb` with Active Storage images
- Final Cut view

**Outputs:**
- `app/services/png_export_service.rb`
- "Export to Figma" button on Final Cut view
- `test/services/png_export_service_test.rb`

**Acceptance criteria:**
- [x] "Export to Figma" downloads a zip file
- [x] Zip contains one PNG per slide, named `01-slide-title.png` (position-title format)
- [x] Images are the original generated resolution
- [x] Tests pass

**Dependencies:** None (within this epic)

---

### Story 10.3: Project Zip Export

**Description:** Export the entire project as a zip archive containing: all vision images (organized by conjuring), conjuring metadata (grimoire_text, timestamps), slide descriptions, and the grimoire. This is for backup, sharing, and reproducibility.

**Inputs:**
- Design doc project export (line 491)
- All project models

**Outputs:**
- `app/services/project_export_service.rb`
- "Export project" button on Final Cut view
- `test/services/project_export_service_test.rb`

**Acceptance criteria:**
- [x] "Export project" downloads a zip file
- [x] Zip structure: `project-name/grimoire.txt`, `project-name/slides/*.txt`, `project-name/conjurings/{run-N}/*.png`, `project-name/conjurings/{run-N}/metadata.json`
- [x] Metadata includes grimoire_text, slide_text, prompt, refinement, selected status for each vision
- [x] Tests pass

**Dependencies:** None (within this epic)

---

## Implementation Order

1. **Story 10.1** — PDF is the primary export format (most commonly needed)
2. **Story 10.2** — PNG folder is a simpler variant of the zip logic
3. **Story 10.3** — Full project export is the most complex but lowest urgency
