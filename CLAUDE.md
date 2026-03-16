# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About

Conjure is a SaaS presentation/visual content generation tool built with Rails 8.1. It uses a magical theme for its domain language (Grimoire, Incantation, Vision, etc.). The app is early-stage with scaffolding in place but minimal models/controllers so far.

## Common Commands

### Development
- `bin/setup` — install deps, prepare DB, start server
- `bin/dev` — start dev server (Rails + Tailwind watcher via foreman, port 3000)

### Testing
- `bundle exec rspec` — run all specs
- `bundle exec rspec spec/models/grimoire_spec.rb` — run a single spec file
- `bundle exec rspec spec/models/grimoire_spec.rb:42` — run a single example by line number
- Uses RSpec + FactoryBot (not Minitest). Follow red/green TDD: write spec first, verify it fails for the right reason, then implement.

### Linting & Security
- `bin/rubocop` — lint Ruby (uses rubocop-rails-omakase style)
- `bin/rubocop -a` — auto-fix lint issues
- `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` — security analysis
- `bin/bundler-audit` — gem vulnerability audit
- `bin/importmap audit` — JS dependency audit

### CI
- `bin/ci` — runs full CI pipeline locally (setup, rubocop, audits, brakeman, tests, seed test)

### Database
- `bin/rails db:prepare` — create/migrate DB
- `bin/rails db:reset` — drop and recreate DB

## Architecture

- **Framework:** Rails 8.1.2 (Ruby), SQLite3 for all environments
- **Frontend:** Hotwire (Turbo + Stimulus) with Tailwind CSS, import maps (no Node.js/bundler)
- **Asset pipeline:** Propshaft
- **Background jobs:** Solid Queue (runs in-process with Puma in production)
- **Caching:** Solid Cache
- **WebSockets:** Solid Cable (Action Cable backed by SQLite)
- **Deployment:** Docker + Kamal (`config/deploy.yml`)

### Multi-database (production)
Production uses four separate SQLite databases: primary, cache (`db/cache_schema.rb`), queue (`db/queue_schema.rb`), and cable (`db/cable_schema.rb`).

### Design Doc
`docs/design-doc (1).md` contains the full product vision and architecture plan including BYOK (Bring Your Own Key) AI/image generation integration and domain vocabulary.
