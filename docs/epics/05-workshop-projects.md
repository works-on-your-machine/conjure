# Epic: Workshop & Project Management

**Status:** Ready
**Phase:** 2 — Content Management
**Depends on:** Grimoire Library
**Blocks:** Incantations

## Goal

Build the Workshop (home screen) with the project card grid and the new project wizard, so users can create and manage presentations.

## Scope

**In scope:**
- Workshop as root route — project index with card grid
- Project cards showing title, grimoire name, slide count, progress, last modified
- New project wizard: name → grimoire selection → starting point
- Empty state for first-time users
- Project delete action
- Project workspace shell (four-section sidebar that hosts Grimoire/Incantations/Visions/Final Cut sections)

**Out of scope:**
- Thumbnail mosaic on project cards (requires generated visions to exist)
- "Start from a template" option (v0.2)
- "Start from an outline" flow (v0.2 — AI-assisted)

## Stories

### Story 5.1: Workshop Home Screen

**Description:** Create the projects controller with an index action that serves as the app's root route. Display projects as a card grid on the dark background. Each card shows project title, grimoire name, slide count, and last modified date.

**Inputs:**
- `app/models/project.rb` and `app/models/grimoire.rb` from Epic 1
- Design doc Workshop section (lines 322–343, 494–522)
- React prototype `docs/conjure-app-mockup.jsx` — `HomeScreen` component (line 81): header with "Conjure" wordmark + "Grimoire library" and "Conjure new project" buttons. Card grid uses `repeat(auto-fill, minmax(280px, 1fr))`. Each card has `ProjectMosaic` (2×2 thumbnail grid), title in serif/goldLight, grimoire name with ◈ prefix in plum, progress bar (gold when complete, plum when in-progress), and selection count. Includes a dashed-border "New project" card with ✦ icon.
- Application layout and card component from Epic 2

**Outputs:**
- `app/controllers/projects_controller.rb` (index action)
- `app/views/projects/index.html.erb`
- `app/views/projects/_project_card.html.erb`
- Route: `root "projects#index"` and `resources :projects`
- `test/controllers/projects_controller_test.rb`

**Acceptance criteria:**
- [x] Root path (/) shows the Workshop with all projects as cards
- [x] Each card displays: title (serif, gold), grimoire name, slide count, last modified
- [x] Clicking a card navigates to the project workspace
- [x] "Conjure new project" button is prominent at the top
- [x] Tests pass

**Dependencies:** None (within this epic)

---

### Story 5.2: Empty State

**Description:** When there are no projects, display a warm welcome empty state with a path to create the first project. The empty state should feel inviting, not barren.

**Inputs:**
- Design doc empty state description (lines 339–343, 519–522)
- React prototype `docs/conjure-app-mockup.jsx` — empty state at line 94: dashed border container, large ✦ icon, "Your workshop is empty" heading in serif/goldLight, descriptive paragraph in textMuted (max-width 400px centered), two CTAs side by side: "Start from scratch" (gold) and "Start from an outline" (default).
- Empty state partial from Epic 2
- Workshop view from Story 5.1

**Outputs:**
- Updated `app/views/projects/index.html.erb` with conditional empty state
- Empty state content with welcome message and "Start from scratch" CTA

**Acceptance criteria:**
- [x] When no projects exist, a welcome message is displayed instead of an empty grid
- [x] "Start from scratch" button leads to new project flow
- [x] When projects exist, the normal card grid renders

**Dependencies:** Story 5.1

---

### Story 5.3: New Project Wizard

**Description:** Build the new project flow as a multi-step form: (1) name the project, (2) choose a grimoire from the library, (3) choose starting point (blank slate only for v0.1). On completion, create the project and redirect to its workspace.

**Inputs:**
- Design doc New Project Flow (lines 346–359, 513–518)
- React prototype `docs/conjure-app-mockup.jsx` — `NewProjectFlow` component (line 172): 3-step wizard with numbered step indicator (gold circles for completed/active, border-only for future). Step 0: large serif input for project name. Step 1: grimoire selection as stacked cards with `GrimoireStrip`, goldGlow background when selected, "✦ Selected" indicator. Step 2: starting point as radio-style cards with icon (◇/✦/▣), title, and description. Each step has Back/Next navigation. Max-width 640px centered.
- `app/models/project.rb`, `app/models/grimoire.rb`
- Grimoire library views from Epic 4 (for grimoire selection)

**Outputs:**
- `app/views/projects/new.html.erb` (multi-step or single-page form)
- `app/controllers/projects_controller.rb` (new, create actions)
- Grimoire selection component (cards or dropdown)

**Acceptance criteria:**
- [x] User can enter a project name
- [x] User can select an existing grimoire (or create new inline)
- [x] Submitting creates the project associated with the chosen grimoire
- [x] After creation, user is redirected to the project workspace
- [x] Validation: project name is required, grimoire selection is required
- [x] Tests pass

**Dependencies:** Story 5.1

---

### Story 5.4: Project Workspace Shell

**Description:** Create the project show page with the four-section sidebar navigation (Grimoire, Incantations, Visions, Final Cut). Each section links to a nested route or tab within the project. Include the grimoire section — displaying the project's active grimoire with its theme text, variation count selector, and the ability to switch grimoires.

**Inputs:**
- Design doc Project Workspace (lines 542–561)
- React prototype `docs/conjure-app-mockup.jsx` — `Workspace` component (line 261): full-height flex layout. Sidebar (200px) has: "← Workshop" back link, project name in serif/goldLight, grimoire name with ◈ in plum, nav items with icons and goldGlow active state, cost estimate footer ("8 slides × 5 var ≈ $3.20"), and Conjure button with gradient/glow at bottom. Grimoire section (line 316): grimoire selector as horizontal card strips with goldGlow on active, theme description textarea, AI assist ghost buttons.
- Project layout from Epic 2 (Story 2.2)
- `app/models/project.rb`, `app/models/grimoire.rb`

**Outputs:**
- `app/views/projects/show.html.erb` with sidebar and content area
- Grimoire section view (inline or as a partial/nested route)
- `app/controllers/projects_controller.rb` (show action)
- Variation count selector (updates `project.default_variations`)

**Acceptance criteria:**
- [x] GET /projects/:id renders the workspace with sidebar
- [x] Sidebar shows four sections, Grimoire section is the default/first view
- [x] Active grimoire name and full description text are displayed and editable
- [x] User can switch to a different grimoire from their library
- [x] Variation count selector (3, 5, 8, 12, 20) updates the project
- [x] "Back to Workshop" link in sidebar navigates to root
- [x] Tests pass

**Dependencies:** Stories 5.1, 5.3

---

## Implementation Order

1. **Story 5.1** — Index page provides the entry point for the whole app
2. **Story 5.2** — Empty state is small and improves first-launch experience
3. **Story 5.3** — New project flow creates the objects that the workspace displays
4. **Story 5.4** — Workspace shell hosts all project-level features
