# Epic: Grimoire Library

**Status:** Ready
**Phase:** 2 — Content Management
**Depends on:** Data Model, Visual Identity
**Blocks:** Workshop & Project Management

## Goal

Build the Grimoire Library — a grid of grimoire cards where users create, edit, duplicate, and delete their visual world definitions. This is the user's collection of reusable themes.

## Scope

**In scope:**
- Grimoire CRUD (create, read, update, delete)
- Card grid layout matching the design doc aesthetic
- Grimoire editor with full text editing
- Duplicate grimoire action
- Usage count display ("Used in 3 projects")

**Out of scope:**
- AI-assisted grimoire creation (v0.2 feature)
- Mini preview strips showing sample renders (v0.2 feature)
- Grimoire versioning (v0.3 feature)

## Stories

### Story 4.1: Grimoire CRUD Controller & Routes

**Description:** Create the grimoires controller with full CRUD actions and RESTful routes. The index page is the Grimoire Library. Include a create form (modal or dedicated page), edit view, and delete with confirmation.

**Inputs:**
- `app/models/grimoire.rb` from Epic 1
- Design doc Grimoire Library section (lines 361–377)
- React prototype `docs/conjure-app-mockup.jsx` — `GrimoireLibrary` component (line 138): card grid with `repeat(auto-fill, minmax(300px, 1fr))`, each card has `GrimoireStrip` (5 preview thumbnails in a row), name in serif/gold, description with 3-line clamp, usage count, and Duplicate/Edit ghost buttons. Header shows "← Workshop" back link and grimoire count.
- Application layout and shared components from Epic 2

**Outputs:**
- `app/controllers/grimoires_controller.rb`
- `app/views/grimoires/index.html.erb` (library grid)
- `app/views/grimoires/show.html.erb` (full grimoire view/editor)
- `app/views/grimoires/new.html.erb`
- `app/views/grimoires/_form.html.erb`
- Routes: `resources :grimoires`
- `test/controllers/grimoires_controller_test.rb`

**Acceptance criteria:**
- [x] GET /grimoires shows a card grid of all grimoires
- [x] Each card shows name (serif, gold), description preview, and usage count
- [x] GET /grimoires/new renders a create form with name and description fields
- [x] POST /grimoires creates a grimoire and redirects to its show page
- [x] GET /grimoires/:id shows the full grimoire with editable text
- [x] PATCH /grimoires/:id updates the grimoire
- [x] DELETE /grimoires/:id with confirmation deletes the grimoire (cascades via dependent destroy)
- [x] Tests pass

**Dependencies:** None (within this epic)

---

### Story 4.2: Grimoire Duplicate Action

**Description:** Add a "Duplicate" action to grimoires that creates a copy with " (copy)" appended to the name. This lets users fork an existing grimoire as a starting point for variation.

**Inputs:**
- `app/controllers/grimoires_controller.rb` from Story 4.1
- `app/models/grimoire.rb`

**Outputs:**
- New `duplicate` action in grimoires controller
- Route: `post 'grimoires/:id/duplicate'` (or member route)
- Duplicate button on grimoire cards and show page

**Acceptance criteria:**
- [ ] Clicking "Duplicate" creates a new grimoire with the same description and name + " (copy)"
- [ ] Redirects to the new grimoire's edit page
- [ ] The duplicate is fully independent (editing it doesn't affect the original)
- [ ] Tests pass

**Dependencies:** Story 4.1

---

## Implementation Order

1. **Story 4.1** — Full CRUD is needed before any additional actions
2. **Story 4.2** — Duplicate is a small addition on top of working CRUD
