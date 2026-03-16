# Epic: Data Model & Associations

**Status:** Ready
**Phase:** 1 — Foundation
**Depends on:** Nothing
**Blocks:** Settings, Grimoire Library, Generation Engine

## Goal

Create all database tables, Active Record models, and associations so that every subsequent epic has a working data layer to build on.

## Scope

**In scope:**
- Grimoire, Project, Slide, Conjuring, Vision, and Setting models
- All migrations with correct column types, indexes, and foreign keys
- Active Record associations, enums, and scopes
- Active Storage attachment on Vision
- Counter cache on Grimoire (projects_count)
- acts_as_list-style position ordering on Slide
- Seed data for development (sample grimoire, project with slides)

**Out of scope:**
- Controllers, views, or any UI
- Background jobs
- API integrations
- Validation beyond basic presence/uniqueness (will be added in feature epics as needed)

## Stories

### Story 1.1: Grimoire and Project Models

**Description:** Create the Grimoire and Project models with their migrations and association. Grimoire has_many projects; Project belongs_to grimoire. Include the counter cache on Grimoire.

**Inputs:**
- Design doc data model section (lines 66–165)
- `app/models/application_record.rb`

**Outputs:**
- `db/migrate/..._create_grimoires.rb`
- `db/migrate/..._create_projects.rb`
- `app/models/grimoire.rb`
- `app/models/project.rb`
- `test/models/grimoire_test.rb`
- `test/models/project_test.rb`

**Acceptance criteria:**
- [x] Grimoire has columns: name (string, not null), description (text), projects_count (integer, default 0)
- [x] Project has columns: name (string, not null), grimoire_id (references, not null), aspect_ratio (string, default "16:9"), default_variations (integer, default 5)
- [x] `Grimoire.create!(name: "Test").projects.create!(name: "Deck")` works
- [x] Counter cache increments/decrements correctly
- [x] Tests pass

**Dependencies:** None

---

### Story 1.2: Slide Model

**Description:** Create the Slide model belonging to Project with position-based ordering. Slides are the "incantations" — each has a title and description.

**Inputs:**
- Design doc data model section
- `app/models/project.rb` from Story 1.1

**Outputs:**
- `db/migrate/..._create_slides.rb`
- `app/models/slide.rb`
- `test/models/slide_test.rb`
- Updated `app/models/project.rb` (has_many :slides)

**Acceptance criteria:**
- [x] Slide has columns: title (string, not null), description (text), position (integer, not null), project_id (references, not null)
- [x] `project.slides.create!(title: "Intro", description: "...", position: 1)` works
- [x] `project.slides` returns slides ordered by position
- [x] Dependent destroy: deleting a project deletes its slides
- [x] Tests pass

**Dependencies:** Story 1.1

---

### Story 1.3: Conjuring and Vision Models

**Description:** Create the Conjuring and Vision models. Conjuring represents a generation run (belongs_to project). Vision belongs_to both slide and conjuring, has Active Storage image attachment. This is the core of the additive generation model.

**Inputs:**
- Design doc data model and Conjuring model sections (lines 66–204)
- Models from Stories 1.1 and 1.2

**Outputs:**
- `db/migrate/..._create_conjurings.rb`
- `db/migrate/..._create_visions.rb`
- `app/models/conjuring.rb`
- `app/models/vision.rb`
- `test/models/conjuring_test.rb`
- `test/models/vision_test.rb`
- Updated `app/models/project.rb` (has_many :conjurings, has_many :visions through :conjurings)
- Updated `app/models/slide.rb` (has_many :visions)

**Acceptance criteria:**
- [ ] Conjuring has columns: project_id (references, not null), grimoire_text (text, not null), variations_count (integer, not null), status (integer, default 0)
- [ ] Conjuring has enum: `status { pending: 0, generating: 1, complete: 2, failed: 3 }`
- [ ] Vision has columns: slide_id (references, not null), conjuring_id (references, not null), position (integer), slide_text (text), prompt (text), refinement (text, nullable), selected (boolean, default false)
- [ ] Vision `has_one_attached :image`
- [ ] `project.visions` returns visions through conjurings
- [ ] Dependent destroy chains work (project → conjurings → visions)
- [ ] Tests pass

**Dependencies:** Stories 1.1, 1.2

---

### Story 1.4: Setting Model and Seed Data

**Description:** Create the Setting model for BYOK API keys and user defaults. Also create seed data for development with a sample grimoire, project, and slides.

**Inputs:**
- Design doc Setting model section (lines 113–121)
- All models from previous stories

**Outputs:**
- `db/migrate/..._create_settings.rb`
- `app/models/setting.rb`
- `test/models/setting_test.rb`
- `db/seeds.rb` (updated with sample data)

**Acceptance criteria:**
- [ ] Setting is a singleton-style model (one row, fetched via `Setting.current` or similar class method)
- [ ] Setting has columns: nano_banana_api_key (string, encrypted), llm_api_key (string, encrypted), default_variations (integer, default 5), default_aspect_ratio (string, default "16:9")
- [ ] API key columns use Active Record encryption
- [ ] `bin/rails db:seed` creates a sample grimoire, project with 3-4 slides
- [ ] Tests pass

**Dependencies:** Stories 1.1, 1.2, 1.3

---

## Implementation Order

1. **Story 1.1** — Grimoire and Project are the root of the data model; everything else references them
2. **Story 1.2** — Slides depend on Project
3. **Story 1.3** — Conjuring and Vision depend on Project and Slide; this is the most complex migration
4. **Story 1.4** — Setting is independent but seeds need all models to exist
