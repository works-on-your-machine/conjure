# Conjure — Epics

## Status Key
- **Done** — Shipped and working
- **In Progress** — Currently being built
- **Ready** — Spec'd and ready to implement
- **Backlog** — Planned, not yet spec'd

---

## Phase 1: Foundation
Get the data model, visual identity, and application shell in place so all feature work has somewhere to land.

| Epic | Status | Depends On | File |
|------|--------|------------|------|
| Data Model & Associations | Done | Nothing | [docs/epics/01-data-model.md](epics/01-data-model.md) |
| Visual Identity & Application Layout | Done | Nothing | [docs/epics/02-visual-identity.md](epics/02-visual-identity.md) |

## Phase 2: Content Management
Build the screens where users manage settings, grimoires, projects, and slides — everything needed before generation.

| Epic | Status | Depends On | File |
|------|--------|------------|------|
| Settings & BYOK Configuration | Done | Data Model | [docs/epics/03-settings.md](epics/03-settings.md) |
| Grimoire Library | Done | Data Model, Visual Identity | [docs/epics/04-grimoire-library.md](epics/04-grimoire-library.md) |
| Workshop & Project Management | Done | Grimoire Library | [docs/epics/05-workshop-projects.md](epics/05-workshop-projects.md) |
| Incantations (Slide Editor) | Done | Workshop & Project Management | [docs/epics/06-incantations.md](epics/06-incantations.md) |

## Phase 3: Generation Pipeline
Wire up the generation engine, background jobs, real-time updates, and the vision wall — the core product experience.

| Epic | Status | Depends On | File |
|------|--------|------------|------|
| Generation Engine & Background Jobs | In Progress | Data Model, Settings | [docs/epics/07-generation-engine.md](epics/07-generation-engine.md) |
| Visions Wall | Ready | Generation Engine, Incantations | [docs/epics/08-visions-wall.md](epics/08-visions-wall.md) |

## Phase 4: Assembly & Export
Complete the workflow with the Final Cut assembly view, refinement, and all export options.

| Epic | Status | Depends On | File |
|------|--------|------------|------|
| Final Cut & Refinement | Ready | Visions Wall | [docs/epics/09-final-cut.md](epics/09-final-cut.md) |
| Export | Ready | Final Cut | [docs/epics/10-export.md](epics/10-export.md) |
