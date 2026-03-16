# Epic: Visual Identity & Application Layout

**Status:** Ready
**Phase:** 1 — Foundation
**Depends on:** Nothing
**Blocks:** Grimoire Library, Workshop & Project Management

## Goal

Establish the Conjure visual identity (dark plum/gold palette, typography, component styles) and application layout so all feature screens share a consistent aesthetic from the start.

## Scope

**In scope:**
- Tailwind CSS configuration with Conjure color palette and custom fonts
- Google Fonts integration (Cormorant Garamond + DM Sans)
- Application layout with header and navigation shell
- Reusable UI patterns: gold buttons, card components, form inputs, gold glow selection state
- Dark theme background and typography hierarchy
- The ✦ symbol styling for selection indicators

**Out of scope:**
- Feature-specific views (grimoire cards, project cards, etc.)
- Stimulus controllers for interactive behavior
- Responsive/mobile optimization (defer to later polish)

## Stories

### Story 2.1: Tailwind Configuration & Typography

**Description:** Configure Tailwind with the Conjure color palette and import Google Fonts. The palette is: deep plum/charcoal (#1e1a2e) background, warm gold (#c4935a) accents, aged parchment (#e8d5b5), muted plum (#7b6b8a) secondary. Fonts are Cormorant Garamond (display) and DM Sans (body).

**Inputs:**
- Design doc Brand & Identity section (lines 19–42)
- React prototype `docs/conjure-app-mockup.jsx` — the `C` color constants object (line 5–9) has the exact hex values and opacity variants for every color token. The `serif`/`sans` font constants (lines 11–12) define the font stacks.
- `app/views/layouts/application.html.erb`
- Tailwind CSS configuration (check for `config/tailwind.config.js` or inline config)

**Outputs:**
- Updated Tailwind configuration with custom colors (`plum`, `gold`, `parchment`, `muted`) and font families (`display`, `body`)
- Updated application layout to include Google Fonts `<link>` tags
- A test page or partial demonstrating the palette and typography renders correctly

**Acceptance criteria:**
- [x] Tailwind classes like `bg-plum`, `text-gold`, `font-display`, `font-body` work in templates
- [x] Cormorant Garamond loads for headings, DM Sans for body text
- [x] Background defaults to the deep plum/charcoal
- [x] `bin/rails tailwindcss:build` completes without errors

**Dependencies:** None

---

### Story 2.2: Application Layout & Navigation Shell

**Description:** Create the main application layout with the dark background, a header with the Conjure wordmark, and navigation links (Workshop, Grimoire Library, Settings). This layout wraps all pages. Also create a project-specific layout variant with the four-section sidebar (Grimoire, Incantations, Visions, Final Cut) that will be used inside project views.

**Inputs:**
- Design doc Project Workspace section (lines 542–549)
- React prototype `docs/conjure-app-mockup.jsx` — the `Workspace` component (line 261) has the exact sidebar structure: 200px width, border-right, nav items with icons (◈ ◇ ◆ ▣), active state using `goldGlow` background, cost estimate in sidebar footer, and the Conjure button with gradient + glow shadow at the bottom. The `HomeScreen` component (line 81) shows the top-level header layout with "Conjure" wordmark + nav buttons.
- `app/views/layouts/application.html.erb`

**Outputs:**
- Updated `app/views/layouts/application.html.erb` with dark theme, header, nav
- New `app/views/layouts/project.html.erb` (or a shared partial) with sidebar navigation
- `app/helpers/application_helper.rb` with any layout helper methods

**Acceptance criteria:**
- [x] All pages render with deep plum background and gold accented header
- [x] Header shows "Conjure" wordmark in Cormorant Garamond and nav links
- [x] Project layout shows four-section sidebar with section links
- [x] Sidebar highlights the active section
- [x] "Back to Workshop" link in sidebar returns to root

**Dependencies:** Story 2.1

---

### Story 2.3: Shared UI Components

**Description:** Create reusable view partials for common UI elements: gold gradient button (the "Conjure" button style), card component (used for projects, grimoires), form inputs styled for dark theme, gold glow selection indicator with ✦, and empty state placeholder. Convert the React shared components to ERB partials.

**Inputs:**
- React prototype `docs/conjure-app-mockup.jsx` — convert these React components to ERB partials:
  - `Btn` (line 45): four variants (default, gold, ghost, danger) with exact styles
  - `TextArea` (line 50): dark surface background, border, padding, font
  - `Input` (line 53): same dark surface treatment
  - `Label` (line 56): uppercase, letter-spaced, dim color
  - `Variation` (line 59): 16:9 aspect ratio, gold glow border/shadow on selection, ✦ badge, scale(1.02) on selected, scanline overlay for pirate theme
  - Empty state pattern (line 94): dashed border, ✦ icon, centered text with CTAs
- Tailwind config from Story 2.1

**Outputs:**
- `app/views/shared/_button.html.erb` (or similar partials directory)
- `app/views/shared/_card.html.erb`
- `app/views/shared/_empty_state.html.erb`
- Form input styling via Tailwind (may be in a shared partial or application CSS)

**Acceptance criteria:**
- [ ] Gold gradient button renders with warm glow shadow, supports "Conjure" and "Re-conjure" text variants
- [ ] Card component has dark background, subtle border, hover state
- [ ] Gold glow selection state (border + shadow + ✦) can be applied to any element
- [ ] Form inputs are styled for dark background (light text, subtle borders)
- [ ] Empty state partial accepts title and description content

**Dependencies:** Story 2.1

---

## Implementation Order

1. **Story 2.1** — Colors and fonts must exist before any styled components
2. **Story 2.2** — Layout provides the page structure everything renders within
3. **Story 2.3** — Shared components build on the palette and live inside the layout
