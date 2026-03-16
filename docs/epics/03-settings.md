# Epic: Settings & BYOK Configuration

**Status:** Ready
**Phase:** 2 — Content Management
**Depends on:** Data Model
**Blocks:** Generation Engine

## Goal

Give users a settings screen to manage their BYOK API keys (Nano Banana 2, LLM) and app defaults (variation count, aspect ratio) so the generation engine has credentials to work with.

## Scope

**In scope:**
- Settings controller with show/update actions
- Form for API key entry (masked display for existing keys)
- Default variation count and aspect ratio settings
- Storage usage display (total disk usage across all visions)
- Basic storage cleanup actions (clear unselected visions)

**Out of scope:**
- Per-conjuring or per-project cleanup (deferred to Visions Wall epic)
- API key validation/testing against external services
- About/version info section

## Stories

### Story 3.1: Settings Controller & API Key Management

**Description:** Create a settings controller and view that lets users view and update their BYOK API keys and default preferences. API keys should display masked (e.g., "sk-...abc") when already set. The Setting model from Epic 1 stores these values with Active Record encryption.

**Inputs:**
- `app/models/setting.rb` from Epic 1
- Design doc Settings Screen section (lines 377–386)
- Application layout from Epic 2

**Outputs:**
- `app/controllers/settings_controller.rb`
- `app/views/settings/show.html.erb`
- Route: `resource :settings, only: [:show, :update]`
- `test/controllers/settings_controller_test.rb`

**Acceptance criteria:**
- [x] GET /settings renders the settings form with current values
- [x] API keys display masked when present, empty field when not set
- [x] PATCH /settings updates API keys and defaults, redirects back with flash notice
- [x] Submitting an empty API key field does not overwrite an existing key
- [x] Default variations and aspect ratio are editable
- [x] Tests pass

**Dependencies:** None (within this epic; depends on Epic 1 for Setting model)

---

### Story 3.2: Storage Usage Display

**Description:** Add a storage section to the settings page showing total disk usage for generated vision images across all projects. Include a button to clear all unselected visions (bulk cleanup).

**Inputs:**
- `app/models/vision.rb` (Active Storage attachment)
- Settings view from Story 3.1

**Outputs:**
- Updated `app/views/settings/show.html.erb` with storage section
- `app/models/vision.rb` — scope or class method for calculating total storage
- Cleanup action in settings controller

**Acceptance criteria:**
- [x] Settings page shows total vision count and approximate disk usage
- [x] "Clear unselected visions" button deletes all visions where `selected: false` and their attached images
- [x] Confirmation dialog before destructive cleanup action
- [x] Page refreshes after cleanup showing updated counts
- [x] Tests pass

**Dependencies:** Story 3.1

---

## Implementation Order

1. **Story 3.1** — Core settings screen with API key management (critical path for generation)
2. **Story 3.2** — Storage display is additive and lower priority
