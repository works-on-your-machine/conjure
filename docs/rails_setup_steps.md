# Conjure: Rails App Setup Steps

## Prerequisites

- Ruby 3.3+ (recommend using rbenv or asdf)
- Rails 8.0+
- ImageMagick (for image processing / PDF export)

## 1. Create the Rails app

```bash
rails new conjure \
  --database=sqlite3 \
  --css=tailwind \
  --skip-jbuilder \
  --skip-action-mailbox \
  --skip-action-mailer \
  --skip-action-text

cd conjure
```

This gives you Rails 8 with SQLite, Tailwind, Hotwire (Turbo + Stimulus included by default), Solid Queue, and Solid Cache — all out of the box.

## 2. Add required gems

```ruby
# Gemfile — add these:

# Image processing
gem "image_processing", "~> 1.2"  # for Active Storage variants
gem "mini_magick"                  # for PDF assembly

# Slide ordering
gem "acts_as_list"

# HTTP client for API calls
gem "faraday"

# JSON parsing (for API responses)
gem "oj"
```

```bash
bundle install
```

## 3. Configure Active Storage

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

This creates the Active Storage tables for file attachments (used by Vision's `has_one_attached :image`).

## 4. Generate models

```bash
# Grimoire
bin/rails generate model Grimoire \
  name:string \
  description:text \
  projects_count:integer

# Project
bin/rails generate model Project \
  name:string \
  grimoire:references \
  aspect_ratio:string \
  default_variations:integer

# Slide
bin/rails generate model Slide \
  title:string \
  description:text \
  position:integer \
  project:references

# Conjuring
bin/rails generate model Conjuring \
  project:references \
  grimoire_text:text \
  variations_count:integer \
  status:integer

# Vision
bin/rails generate model Vision \
  slide:references \
  conjuring:references \
  position:integer \
  slide_text:text \
  prompt:text \
  refinement:text \
  selected:boolean
```

```bash
bin/rails db:migrate
```

## 5. Set up model associations

Create/update the model files per the design doc:

- `app/models/grimoire.rb` — `has_many :projects`, counter cache
- `app/models/project.rb` — `belongs_to :grimoire`, `has_many :slides`, `has_many :conjurings`, `has_many :visions through: :conjurings`
- `app/models/slide.rb` — `belongs_to :project`, `has_many :visions`, `acts_as_list scope: :project`
- `app/models/conjuring.rb` — `belongs_to :project`, `has_many :visions`, `enum :status`
- `app/models/vision.rb` — `belongs_to :slide`, `belongs_to :conjuring`, `has_one_attached :image`

## 6. Configure Solid Queue

Solid Queue ships with Rails 8 by default. Verify it's configured:

```bash
# Check config/queue.yml exists
# Check config/solid_queue.yml exists
# Verify Gemfile has solid_queue
```

Create the job:

```bash
bin/rails generate job Conjuring
```

This creates `app/jobs/conjuring_job.rb` — this is where the generation pipeline lives.

## 7. Set up Action Cable for Turbo Streams

Action Cable is included by default in Rails 8. Verify:

```ruby
# config/cable.yml should have:
development:
  adapter: solid_cable
```

This enables Turbo Stream broadcasts for real-time generation progress.

## 8. Configure encrypted credentials

```bash
bin/rails credentials:edit
```

Add the API key structure:

```yaml
nano_banana:
  api_key: ""

llm:
  provider: "anthropic"  # or "openai"
  api_key: ""
```

## 9. Generate controllers

```bash
# Main resource controllers
bin/rails generate controller Projects index show new create edit update destroy
bin/rails generate controller Grimoires index show new create edit update destroy
bin/rails generate controller Slides create update destroy
bin/rails generate controller Conjurings create show
bin/rails generate controller Visions update  # for selection toggling
bin/rails generate controller Settings show update

# Static / home
bin/rails generate controller Workshop index  # home screen
bin/rails generate controller Exports create  # PDF / Figma / zip export
```

## 10. Set up routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "workshop#index"

  resources :grimoires
  
  resources :projects do
    resources :slides, except: [:index, :show] do
      member do
        patch :move  # for reordering
      end
    end
    resources :conjurings, only: [:create, :show]
    resources :visions, only: [:update]  # toggle selection
    resource :export, only: [:create]    # PDF / Figma / zip
  end

  resource :settings, only: [:show, :update]
end
```

## 11. Set up Tailwind with the Conjure color palette

Update `app/assets/stylesheets/application.tailwind.css` and/or `tailwind.config.js`:

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        conjure: {
          bg: '#1e1a2e',
          'bg-deep': '#161323',
          surface: '#2d2540',
          'surface-light': '#3a3255',
          gold: '#c4935a',
          'gold-light': '#e8d5b5',
          'gold-dim': '#a38050',
          plum: '#7b6b8a',
          text: '#e8e0d4',
          'text-muted': '#9a8e80',
          'text-dim': '#6a6058',
        }
      },
      fontFamily: {
        display: ['"Cormorant Garamond"', 'Georgia', 'serif'],
        body: ['"DM Sans"', 'system-ui', 'sans-serif'],
      }
    }
  }
}
```

Add the Google Fonts to your layout:

```erb
<%# app/views/layouts/application.html.erb — in <head> %>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet">
```

## 12. Generate Stimulus controllers

```bash
bin/rails generate stimulus vision_selector    # gold glow toggle on click
bin/rails generate stimulus cost_estimator     # live cost calculation
bin/rails generate stimulus slide_reorder      # drag-to-reorder slides
bin/rails generate stimulus wall_filter        # filter visions by conjuring
bin/rails generate stimulus provenance_panel   # inspect a vision's history
bin/rails generate stimulus grimoire_switcher  # switch grimoires within project
```

## 13. Create service objects

```bash
mkdir -p app/services

touch app/services/generation_service.rb
touch app/services/local_provider.rb
touch app/services/prompt_assembler.rb
```

- `GenerationService` — orchestrates the generation pipeline
- `LocalProvider` — calls Nano Banana 2 API with BYOK credentials
- `PromptAssembler` — uses the LLM to merge grimoire_text + slide_text into an effective image generation prompt

## 14. Set up bin/setup

Update `bin/setup` to handle the first-run experience:

```ruby
#!/usr/bin/env ruby
require "fileutils"

APP_ROOT = File.expand_path("..", __dir__)

def system!(*args)
  system(*args, exception: true)
end

FileUtils.chdir APP_ROOT do
  puts "== Installing dependencies =="
  system! "gem install bundler --conservative"
  system("bundle check") || system!("bundle install")

  puts "\n== Preparing database =="
  system! "bin/rails db:prepare"

  puts "\n== Configuring API keys =="
  unless File.exist?("config/credentials.yml.enc")
    puts "Let's set up your API keys."
    print "Nano Banana 2 API key: "
    nb_key = $stdin.gets.chomp
    print "LLM API key (Claude/OpenAI): "
    llm_key = $stdin.gets.chomp
    # Write to credentials programmatically
    # (or prompt user to run bin/rails credentials:edit)
  end

  puts "\n== Removing old logs and tempfiles =="
  system! "bin/rails log:clear tmp:clear"

  puts "\n== Done! Run bin/dev to start Conjure =="
end
```

## 15. Set up bin/dev

The default `bin/dev` uses Foreman with a `Procfile.dev`:

```
# Procfile.dev
web: bin/rails server -p 3000
queue: bin/rails solid_queue:start
css: bin/rails tailwindcss:watch
```

This starts the Rails server, Solid Queue worker, and Tailwind CSS watcher in one command.

## 16. Copy the design doc into the repo

```bash
cp /path/to/design-doc.md docs/DESIGN.md
```

## Summary: what you have after setup

```
conjure/
├── app/
│   ├── controllers/
│   │   ├── workshop_controller.rb      # home screen
│   │   ├── projects_controller.rb
│   │   ├── grimoires_controller.rb
│   │   ├── slides_controller.rb
│   │   ├── conjurings_controller.rb
│   │   ├── visions_controller.rb
│   │   ├── settings_controller.rb
│   │   └── exports_controller.rb
│   ├── models/
│   │   ├── grimoire.rb
│   │   ├── project.rb
│   │   ├── slide.rb
│   │   ├── conjuring.rb
│   │   └── vision.rb
│   ├── jobs/
│   │   └── conjuring_job.rb
│   ├── services/
│   │   ├── generation_service.rb
│   │   ├── local_provider.rb
│   │   └── prompt_assembler.rb
│   ├── javascript/
│   │   └── controllers/              # Stimulus controllers
│   │       ├── vision_selector_controller.js
│   │       ├── cost_estimator_controller.js
│   │       ├── slide_reorder_controller.js
│   │       ├── wall_filter_controller.js
│   │       ├── provenance_panel_controller.js
│   │       └── grimoire_switcher_controller.js
│   └── views/
│       ├── layouts/
│       ├── workshop/                  # home screen
│       ├── projects/                  # workspace views
│       ├── grimoires/
│       ├── slides/
│       ├── conjurings/
│       ├── visions/
│       ├── settings/
│       └── exports/
├── config/
│   ├── routes.rb
│   ├── tailwind.config.js
│   └── credentials.yml.enc
├── db/
│   └── migrate/
├── docs/
│   └── DESIGN.md
├── bin/
│   ├── setup
│   └── dev
├── Procfile.dev
├── Gemfile
├── LICENSE                            # MIT
└── README.md
```

## Next: hand this to Claude Code

With this setup complete, you can hand the design doc to Claude Code and start building out the views, controllers, and generation pipeline. The models, routes, and service object structure are all scaffolded and ready to flesh out.
