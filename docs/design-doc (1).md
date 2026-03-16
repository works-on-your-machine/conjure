# Conjure: Design Document

## Vision

The spiritual successor to MonkeysPaw. Where MonkeysPaw conjured websites from wishes, Conjure summons entire visual worlds for presentations.

You describe a vibe. You get twenty parallel universes. You walk through them like a curator and assemble your favorite reality.

**The wall of variations is the product.** Everything else is scaffolding.

## Core Principles

- **Directing, not editing.** The user is an art director reviewing dailies, not a designer pushing pixels.
- **Surprise is load-bearing.** Each variation should be a genuine creative interpretation, not a color swap. Too much control kills the magic.
- **The process is the story.** The experience of using this tool should itself be something worth telling people about at a bar.
- **AI assists, never takes over.** AI shows up at every stage to help, but the user always sees and edits the text before anything gets generated. The AI is the assistant, the user is the director.
- **BYOK.** Users bring their own API keys for image generation and LLM text generation.

## Brand & Identity

### Name: Conjure

Extends the MonkeysPaw lineage without being a sequel. Evokes what the user is doing — summoning visions from descriptions — not what the tool is doing under the hood.

### Visual Identity

- **Palette:** Deep plum/charcoal (#1e1a2e) background, warm gold (#c4935a) accents, aged parchment tones (#e8d5b5). Muted plum (#7b6b8a) for secondary elements.
- **Feeling:** Warm alchemy. An old magic workshop. The generated slides are specimens in a cabinet of curiosities.
- **Typography:** Cormorant Garamond (display/headings), DM Sans (UI/body). The serif gives warmth and personality; the sans keeps the interface functional.
- **Selection indicator:** Gold glow border with warm shadow — like a spell catching fire. Not a checkbox or a ring. The ✦ symbol as the selection mark.
- **Generate button:** Says "Conjure" (or "Re-conjure" after first generation). Gold gradient with warm glow shadow.

### Vocabulary

The entire UI uses a consistent magical vocabulary:

- **Grimoire** — the theme (visual world definition)
- **Incantations** — the slide descriptions
- **Visions** — the generated variations
- **Conjure / Summon** — the act of generating
- **Final Cut** — the assembled presentation
- **Workshop** — the home screen (project index)

## Architecture

### Stack

- **Framework:** Rails 8 with SQLite
- **Background jobs:** Solid Queue — image generation cannot block web requests
- **Frontend:** Hotwire (Turbo + Stimulus). No React, no JavaScript framework, no build step, no node_modules.
- **CSS:** Tailwind CSS via the Rails asset pipeline
- **Image storage:** Active Storage with local disk
- **Image generation:** Nano Banana 2 API (BYOK)
- **Text generation (AI assists):** LLM API — Claude, GPT, etc. (BYOK)
- **API key management:** Rails encrypted credentials
- **Export:** PDF via ImageMagick/MiniMagick or Prawn. Figma export as PNG folder with metadata. Project export as zip.

### Frontend Details

- **Turbo Frames** for the split-pane slide editor, modal content, grimoire switcher
- **Turbo Streams** over Action Cable for real-time generation progress ("Conjuring #3: 12/40 visions complete...")
- **Stimulus controllers** for selection state (gold glow toggle), wall filtering, drag-to-reorder slides, cost estimate calculator

### Data Model

```
┌─────────────────────────────────────────────┐
│                                              │
│  ┌───────────────┐    ┌──────────────────┐  │
│  │   Grimoire     │    │    Project       │  │
│  │                │    │                  │  │
│  │                │◄───│  grimoire_id     │  │
│  │  - name        │    │                  │  │
│  │  - description │    │  - name          │  │
│  │  (projects_    │    │  - aspect_ratio  │  │
│  │   count via    │    │  - default_      │  │
│  │   counter      │    │    variations    │  │
│  │   cache)       │    │  - created_at    │  │
│  │                │    │  - updated_at    │  │
│  └───────────────┘    └──┬────────┬──────┘  │
│                           │        │         │
│              ┌────────────┘        │         │
│              ▼                     ▼         │
│  ┌──────────────────┐  ┌─────────────────┐  │
│  │   Slide           │  │  Conjuring      │  │
│  │   (incantation)   │  │  (gen run)      │  │
│  │                   │  │                 │  │
│  │  - title          │  │  - project_id   │  │
│  │  - description    │  │  - grimoire_    │  │
│  │  - position       │  │    text         │  │
│  │  - project_id     │  │  - variations_  │  │
│  │                   │  │    count        │  │
│  │  (live, editable  │  │  - status       │  │
│  │   current state)  │  │  - created_at   │  │
│  └──────────────────┘  └────────┬────────┘  │
│              │                   │           │
│              │    ┌──────────────┘           │
│              ▼    ▼                          │
│  ┌───────────────────────────────────────┐  │
│  │   Vision (generated image)             │  │
│  │                                        │  │
│  │  - slide_id                            │  │
│  │  - conjuring_id                        │  │
│  │  - position (1, 2, 3... within run)    │  │
│  │  - has_one_attached :image             │  │
│  │  - slide_text (snapshot at gen time)   │  │
│  │  - prompt (assembled, sent to API)     │  │
│  │  - refinement (nullable)               │  │
│  │  - selected (boolean, default false)   │  │
│  │  - created_at                          │  │
│  └───────────────────────────────────────┘  │
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │   Setting                              │  │
│  │   (or use Rails encrypted credentials) │  │
│  │                                        │  │
│  │   - nano_banana_api_key (encrypted)    │  │
│  │   - llm_api_key (encrypted)            │  │
│  │   - default_variations                 │  │
│  │   - default_aspect_ratio               │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Rails Associations

```ruby
class Grimoire < ApplicationRecord
  has_many :projects
  # counter cache: projects_count
end

class Project < ApplicationRecord
  belongs_to :grimoire
  has_many :slides, -> { order(:position) }, dependent: :destroy
  has_many :conjurings, dependent: :destroy
  has_many :visions, through: :conjurings
end

class Slide < ApplicationRecord
  belongs_to :project
  has_many :visions, dependent: :destroy
  # acts_as_list scope: :project
end

class Conjuring < ApplicationRecord
  belongs_to :project
  has_many :visions, dependent: :destroy

  enum :status, { pending: 0, generating: 1, complete: 2, failed: 3 }
  # grimoire_text: frozen copy at generation time
  # variations_count: how many per slide for this run
end

class Vision < ApplicationRecord
  belongs_to :slide
  belongs_to :conjuring
  has_one_attached :image
  # slide_text: frozen copy of slide description at generation time
  # prompt: the assembled prompt sent to Nano Banana 2
  # refinement: optional refinement instructions (nullable)
  # selected: boolean
  # position: variation number within this conjuring for this slide
end
```

### The Conjuring Model (Additive Generation)

**Generation is additive, not destructive.** Every time the user hits Conjure, a new Conjuring record is created. Old visions are never deleted or replaced — they stay in the pool. The user cherry-picks across ALL conjurings freely.

A **Conjuring** represents a single generation run. It captures:
- **grimoire_text** — The exact grimoire description at the moment of generation (frozen copy, not a reference). If the user tweaks the grimoire between runs, each Conjuring preserves what was actually used.
- **variations_count** — How many variations were requested for this run
- **status** — pending / generating / complete / failed (enum)
- **created_at** — When this run happened

A **Vision** belongs to both a Slide and a Conjuring. It captures:
- **slide_text** — The exact slide description at the moment of generation (frozen copy). If the user edits the slide between runs, the provenance is preserved.
- **prompt** — The actual prompt sent to Nano Banana 2 (the LLM-assembled merge of grimoire + slide description + any refinement). Useful for debugging and learning what prompts produce what results.
- **refinement** — If this vision was refined from a previous one, the refinement instructions that were added (nullable).
- **selected** — Boolean, whether this vision is currently selected for the final cut.

**This enables the full iterative workflow:**

1. Generate 5 variations for all 8 slides → Conjuring #1 (40 visions)
2. Tweak the grimoire, adjust 2 slide descriptions → still have all 40 visions from run 1
3. Generate 5 more variations → Conjuring #2 (40 new visions, 80 total)
4. Love the title slide from Conjuring #1 but prefer slide 3 from Conjuring #2 → select freely across both
5. Add 2 new slides → generate just those → Conjuring #3 (10 visions for the 2 new slides, 90 total)
6. Refine slide 5 with "make the headline bigger" → Conjuring #4 (5 refined variations of just that slide, 95 total)

**The wall shows ALL visions for a slide, grouped or sorted by Conjuring.** The user can:
- See visions from all runs mixed together (default — best overall selection)
- Filter to a specific Conjuring ("show me just what I generated an hour ago")
- Inspect any vision to see exactly what grimoire text + slide description + prompt produced it

**Provenance is always available.** Click any vision in the wall and see:
- Which Conjuring produced it (timestamp, run number)
- `conjuring.grimoire_text` — the grimoire that was active at generation time
- `vision.slide_text` — the slide description that was used
- `vision.prompt` — the assembled prompt that was sent to Nano Banana 2
- `vision.refinement` — any refinement instructions that were applied

This is valuable not just for the user's workflow but also for learning — "oh, that phrasing in the grimoire is what made the glitch effect work so well."

### Image Storage

Generated images are stored via Active Storage (local disk by default).

```
storage/
└── visions/
    └── project_{id}/
        └── conjuring_{id}/
            ├── slide_1_v1.png
            ├── slide_1_v2.png
            ├── slide_2_v1.png
            └── ...
```

The Vision model uses `has_one_attached :image`.

### Generation Pipeline

```
User hits "Conjure"
        │
        ▼
┌──────────────────┐
│  Create Conjuring │
│  record           │
│                   │
│  Freeze grimoire  │
│  → conjuring.     │
│    grimoire_text  │
│                   │
│  Freeze each slide│
│  description      │
│  → vision.        │
│    slide_text     │
│  (per slide in    │
│   scope)          │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌────────────────────┐
│  Prompt Assembly  │     │  For each slide    │
│                   │     │  in scope:         │
│  LLM merges       │────▶│                    │
│  grimoire_text    │     │  grimoire_text     │
│  + slide_text     │     │  + slide_text      │
│  + refinement     │     │  → assembled prompt │
│  into effective   │     │                    │
│  image gen prompt │     │  Store as          │
│                   │     │  vision.prompt     │
└──────────────────┘     └─────────┬──────────┘
                                   │
                                   ▼
                          ┌────────────────┐
                          │  Nano Banana 2  │
                          │  (BYOK)         │
                          │                 │
                          │  Returns N      │
                          │  images per     │
                          │  slide          │
                          └────────┬───────┘
                                   │
                                   ▼
                          ┌────────────────┐
                          │  Store Visions  │
                          │                 │
                          │  Image → disk   │
                          │  Metadata → DB  │
                          │  (belongs_to    │
                          │   conjuring +   │
                          │   slide)        │
                          └────────────────┘
```

The prompt assembly step uses an LLM to merge `conjuring.grimoire_text` and `vision.slide_text` into an effective image generation prompt. Refinement prompts get folded in as additional instructions. The assembled prompt is stored as `vision.prompt` for provenance.

**Background processing:** The entire generation pipeline runs in Solid Queue jobs, not in the web request. When the user hits Conjure:
1. A Conjuring record is created with `status: :pending`
2. A `ConjuringJob` is enqueued in Solid Queue
3. The job updates `status: :generating` and processes each slide
4. As each Vision is generated, a Turbo Stream broadcast updates the wall in real time (new image fades in)
5. When complete, `status: :complete` — the wall is fully populated

This means the user can watch visions appear one by one in the wall as they're generated, rather than waiting for the entire batch to finish. The gold glow selection works immediately on any vision that's arrived.

### Generation Service

```ruby
# app/services/generation_service.rb
class GenerationService
  def initialize(provider: LocalProvider.new)
    @provider = provider
  end

  def generate(prompt, count:)
    @provider.generate(prompt, count:)
  end
end

# app/services/local_provider.rb
class LocalProvider
  def generate(prompt, count:)
    # Calls Nano Banana 2 directly with encrypted credentials
  end
end
```

## Data Model: Projects & Grimoires

### Hierarchy

**Grimoires live at the account level.** A grimoire like "Pirate Broadcast" is something you develop once and reuse across multiple presentations. It's part of your creative identity, not tied to any single deck. When you create a project, you select (or create) a grimoire to use. You can switch grimoires mid-project to remix everything.

**Projects are individual presentations.** Each one references a grimoire but contains its own slides, visions, and selections.

### Project Index (Home Screen / Workshop)

The first thing a user sees when opening Conjure. This is the workshop — your collection of presentations, past and in progress.

**Layout:** A grid of project cards on the warm dark background. Each card shows:
- Project title (serif, gold)
- Grimoire name (muted, small)
- Slide count and completion status (e.g. "8 slides — 6/8 visions selected")
- A thumbnail mosaic: tiny previews of 3-4 selected visions, giving a visual fingerprint of the deck's aesthetic
- Last modified date
- Progress bar

**Actions:**
- Click a project card to open it (enters the four-section workspace)
- "Conjure new project" button — prominent, gold, at the top of the grid
- Access to Grimoire Library from header
- Settings link (API key configuration)

**Empty state:** First-time users see a warm welcome with two paths:
1. "Start from scratch" — creates a blank project, walks through grimoire selection → incantation writing
2. "Start from an outline" — opens the outline-to-slides flow immediately, creating the project around the generated content

API keys are already configured if they ran `bin/setup`, so there's no friction — they can start creating immediately.

### New Project Flow

When creating a new project, a three-step wizard:

1. **Name your project** — Simple text input. "What's this presentation called?"
2. **Choose a grimoire** — Browse your grimoire collection. Each grimoire card shows:
   - Name and a short excerpt of the description
   - A mini preview strip: what slides look like in this style (generated from a standard sample set, cached)
   - "Use this grimoire" button
   - Option to create a new grimoire inline
3. **Choose your starting point:**
   - "Start with a blank slate" → Opens to the Incantations section with zero slides
   - "Paste an outline" → Opens the generate-from-outline modal
   - "Start with a template" → Pre-built slide sets for common formats (conference talk, pitch deck, lightning talk, workshop)
4. **Land in the workspace** — The four-section sidebar appears, starting on Incantations

### Grimoire Library

Accessible from both the home screen and from within any project. This is the user's collection of visual worlds.

**Layout:** A grid of grimoire cards. Each shows:
- Grimoire name (serif, gold)
- First few lines of the description as a preview
- Mini preview strip of what this style produces
- Usage count ("Used in 3 projects")
- Edit / Duplicate / Delete actions

**Actions:**
- Click to view/edit the full grimoire text
- "Create new grimoire" — opens the grimoire editor (with AI assists)
- "Duplicate" — copy an existing grimoire as a starting point for variation

### Settings Screen

- **API Keys:** Nano Banana 2 key for image generation, LLM key for AI assists. Stored in Rails encrypted credentials (`config/credentials.yml.enc`). The settings screen provides a UI for updating these without touching the command line.
- **Defaults:** Default variation count, default aspect ratio
- **Storage:** Shows total disk usage for generated visions across all projects, with options to:
  - Clear visions from specific conjurings (e.g. delete old runs you don't need)
  - Clear all unselected visions across all projects (keep only the curated picks)
  - Clear all visions for a specific project
- **About:** Version info, link to GitHub repo

## User Workflow

The complete journey from opening the app to having a finished presentation:

### Phase 0: The Workshop (Home Screen)

The user opens Conjure and sees their project index — all presentations past and in progress, displayed as a grid of cards. Each card shows a visual fingerprint (thumbnail mosaic of selected visions), the project title, grimoire used, and completion status.

From here they either open an existing project or create a new one. New project creation walks them through naming → grimoire selection → starting point (blank, paste an outline, or template).

First-time users see a warm empty state that invites them to either start from scratch or paste an outline. API keys are already configured if they ran `bin/setup`, so there's no friction — they can start creating immediately.

### Phase 1: Grimoire (Theme Setup)

The user defines the visual world their slides inhabit.

**Two paths in:**
1. **Write from scratch** — Describe a vibe in natural language. Not a config. A wish.
2. **AI-assisted** — Describe a vague vibe ("something punk and analog") and hit "AI: I just have a vibe, expand it" to get a full theme description generated. Edit as desired.

**AI assists available:**
- "AI: I just have a vibe, expand it" — Takes a few words and generates a rich theme description
- "AI: Enrich this theme" — Takes an existing theme and adds more detail, texture references, typography suggestions

**The theme is always editable text.** AI generates a draft; the user owns the final version.

### Phase 2: Incantations (Slide Descriptions)

The user defines what each slide should communicate.

**Three paths in:**
1. **Manual** — Write each slide description one by one
2. **Generate from outline** — Paste a brain dump, talk outline, bullet points, or rough notes. AI breaks it into individual slide descriptions with titles. User reviews, edits, reorders, adds, removes.
3. **Hybrid** — Generate the initial set from an outline, then manually refine individual slides

**AI assists available:**
- "AI: Generate slides from outline" — Takes unstructured text and produces structured slide descriptions
- "AI: Expand this description" — Takes a terse slide description and adds visual detail
- "AI: Suggest visual approach" — Given the slide content, suggests how it might be visually represented within the theme

**Slide management:**
- Add new slides with a title
- Remove slides
- Reorder slides (drag or move up/down)
- Each slide is independently editable

### Phase 3: Conjure (The Wall)

The core experience. Hit the Conjure button and watch visions materialize.

**Generation is additive.** Every time you conjure, new visions are added to the pool. Old visions are never deleted or replaced. You can freely cherry-pick across all generation runs.

**The typical iterative workflow:**
1. Write your slides and grimoire, hit Conjure → first batch of visions appears
2. Browse the wall. Some slides look great, others need work.
3. Tweak the grimoire ("more grain texture, less clean"), adjust a few slide descriptions
4. Hit Conjure again → new visions appear alongside the old ones
5. The title slide from run 1 is perfect. Slide 3 looks better after the grimoire tweak. Cherry-pick across both.
6. Add two new slides for a section you forgot → Conjure just those slides → new visions only for those, everything else untouched
7. Refine a specific slide ("make the headline bigger") → generates a few refined variations of just that slide

**The wall shows everything.** All visions for each slide, from all conjurings, with subtle indicators showing which run produced what. The user can filter by conjuring or view everything mixed together.

**Provenance is always available.** Click any vision to see exactly what grimoire text, slide description, and assembled prompt produced it. This is valuable for learning what works — "oh, that phrasing in the grimoire is what made the glitch effect fire."

**Conjuring scope:** The user can choose to conjure all slides, only selected slides, or only slides that don't have visions yet. This keeps generation costs down during the iterative refinement loop.

**Cost estimate updates live** as the user selects scope and variation count.

### Phase 4: Refine

After selecting visions, the user can refine individual slides through prompt-based re-generation.

**What stays in the tool (prompt-level refinement):**
- "Make the headline text larger"
- "Add more VHS static texture"
- "Make the background darker"
- "Change the emphasis to the second line"
- "More negative space around the central image"

**What goes to another tool (pixel-level compositing):**
- Overlaying a specific screenshot onto a monitor in the slide
- Adding a particular image or photo to a specific location
- Precise text positioning or font changes
- Multi-layer composition work

The refinement modal shows the current vision, accepts a text prompt describing the desired change, and re-conjures with those changes folded in. It explicitly notes that compositing work should use the Figma export.

**This boundary is intentional.** Prompt-level refinement keeps the user in the directing/curating headspace. Building a compositor would be a different product entirely.

### Phase 5: Assembly & Export

The user reviews their curated deck in order and exports.

**Assembly view shows:**
- Selected visions in presentation order
- Slide numbers and titles alongside each vision
- Refine button on each slide for last-minute prompt adjustments
- Clear indication of any unselected slides

**Export options:**
- **PDF** — For presenting directly
- **Export to Figma** — For further pixel-level editing, compositing screenshots, overlay work
- **PNG folder** — Individual slide images for maximum flexibility
- **Export project** — Zip archive with all visions, conjuring history, grimoire texts, and slide descriptions — full provenance for sharing/backup/reproducibility

## The Wall UI — Complete Feature Breakdown

### Home Screen (Workshop)

The entry point. Shows all projects as a card grid.

**Project cards show:**
- Project title (serif, gold)
- Grimoire name (muted)
- Slide count and selection progress
- Thumbnail mosaic: 3-4 tiny vision previews as a visual fingerprint
- Last modified date
- Progress bar

**Actions:**
- Click card to open project
- "Conjure new project" button (gold, prominent)
- Access to Grimoire Library
- Settings link

**New project flow:**
1. Name your project
2. Choose a grimoire (browse collection with preview strips, or create new)
3. Choose starting point: blank slate / paste an outline / use a template
4. Land in the workspace

**Empty state (first launch):**
- Warm welcome message
- Two prominent paths: "Start from scratch" and "Start from an outline"
- API keys already configured via `bin/setup` — no setup friction on first launch

### Grimoire Library

Accessible from home screen and from within any project.

**Grimoire cards show:**
- Name (serif, gold)
- Description preview (first few lines)
- Mini preview strip (cached sample renders)
- Usage count ("Used in 3 projects")
- Edit / Duplicate / Delete actions

**Actions:**
- Click to view/edit full grimoire
- Create new grimoire (with AI assists)
- Duplicate existing grimoire as starting point

### Project Workspace

Once inside a project, the four-section sidebar navigation appears:

1. **Grimoire** — Theme for this project (select from library or create new)
2. **Incantations** — Slide description creation and editing
3. **Visions** — The variation wall (core experience)
4. **Final Cut** — Assembly, refinement, and export

A "back to workshop" link in the sidebar returns to the home screen.

### Grimoire Section (Project Level)

- Select from your grimoire library or create a new one
- Shows the active grimoire for this project with full text editor
- Switch grimoire: browse library, pick a different one. Previous visions are preserved — switching grimoire and re-conjuring creates a new Conjuring with the new grimoire, old visions stay in the pool.
- Edits here can optionally save back to the library version, or stay project-local
- AI assist: "I just have a vibe, expand it" — takes a few words, generates full theme
- AI assist: "Enrich this theme" — adds more detail to existing theme
- Variation count selector (3, 5, 8, 12, 20 per slide)
- Cost estimate display (slides × variations × $0.08)
- Conjuring history: see a list of past conjurings for this project with the grimoire text that was used for each

### Incantations Section

Split view: slide list on left, editor on right.

**Slide list:**
- All slides with title and description preview
- Click to select and edit
- Add new slide (title input + button)
- "Generate slides from outline" button opens modal

**Slide editor:**
- Editable title (large serif, inline edit)
- Description textarea (what this slide should show)
- AI assist: "Expand this description" — adds visual detail
- AI assist: "Suggest visual approach" — proposes how to visualize the content
- Move up / Move down buttons for reordering
- Remove slide button

**Generate from outline modal:**
- Large textarea for pasting talk notes, bullet points, brain dumps
- AI generates structured slide descriptions with titles
- User reviews the generated set in the incantations editor
- Can then add, remove, edit, reorder as needed

### Visions Section (The Wall)

The wall shows ALL visions for each slide across all conjurings. Generation is additive — every time you conjure, new visions are added to the pool without removing old ones.

**Default view (all visions):**
- All slides as rows
- All visions for each slide as a scrollable row of thumbnails — grouped by conjuring, most recent first
- Gold glow selection with ✦ indicator
- Conjuring badge on each vision (subtle, e.g. "Run 3" or a timestamp) so you can tell which generation produced it
- Total vision count and selection count displayed

**Filtering:**
- Show all visions (default — cherry-pick across everything)
- Filter to a specific conjuring ("just show me what I generated last")
- Filter to just selected visions (quick review of current picks)

**Provenance panel (click/inspect any vision):**
- Which conjuring produced it (timestamp, run number)
- `conjuring.grimoire_text` — the grimoire active at generation time
- `vision.slide_text` — the slide description used
- `vision.prompt` — the assembled prompt sent to Nano Banana 2
- `vision.refinement` — any refinement instructions applied
- Option to "Re-conjure with these exact inputs" (useful if you want more variations of something that worked)

**Partial conjuring:**
- Select specific slides to re-conjure (don't have to regenerate everything)
- Useful after adding new slides, editing a few descriptions, or refining the grimoire
- New visions appear in the wall alongside existing ones

**Conjuring scope controls (on the Conjure button):**
- "Conjure all slides" — generates variations for every slide in the project
- "Conjure selected slides only" — generates only for slides the user has checked
- "Conjure slides without visions" — generates only for slides that have no visions yet (useful after adding new slides)

**Vision management:**
- Delete individual visions (cleanup)
- Delete all visions from a specific conjuring (bulk cleanup)
- Disk usage indicator ("142 visions, ~580MB")

### Final Cut Section

- Selected visions displayed in presentation order with slide numbers
- Each slide has a **Refine** button
- Unselected slides shown as dashed placeholders
- "Back to visions" navigation

**Refine modal:**
- Shows the current selected vision at the top
- Text prompt input: "Describe your refinement"
- Placeholder examples: "Make the headline text larger", "Add more VHS static texture"
- "Re-conjure with changes" button — creates a new Conjuring scoped to just this slide, with the refinement prompt folded into the generation. The original vision is preserved; refined visions appear alongside it in the wall.
- Note at bottom: "For compositing (adding screenshots, overlaying images), use Export to Figma for pixel-level control."

**Export options:**
- Export PDF (primary, enabled when all slides selected)
- Export to Figma (PNG folder with layout metadata)
- Export project (zip archive with full conjuring history for sharing/backup)
- Back to visions (for further curation)

## Where AI Shows Up

AI assists appear throughout the workflow but never take over. The user always reviews and edits before generation.

| Stage | AI Assist | What It Does |
|-------|-----------|--------------|
| Grimoire | "I just have a vibe, expand it" | Takes a few words → full theme description |
| Grimoire | "Enrich this theme" | Adds detail to existing theme |
| Incantations | "Generate slides from outline" | Brain dump → structured slide descriptions |
| Incantations | "Expand this description" | Terse description → rich visual description |
| Incantations | "Suggest visual approach" | Content → visual representation ideas |
| Visions | Generation engine | `grimoire_text` + `slide_text` → LLM prompt assembly → Nano Banana 2 |
| Final Cut | "Re-conjure with changes" | Selected vision + `refinement` prompt → new conjuring for that slide |

**AI requires two types of API access:**
1. **Image generation** — Nano Banana 2 for creating slide visions
2. **Text generation** — An LLM (Claude, GPT, etc.) for AI assists (theme expansion, outline parsing, prompt assembly)

Both are BYOK, configured via Rails encrypted credentials during `bin/setup`.

## Refinement Boundary

This is an intentional design decision. Two levels of editing exist:

**In-tool (prompt-level refinement):**
- Regenerate a slide with additional instructions
- "Make the headline bigger", "add more static texture", "darker background"
- Stays in the directing/curating headspace
- Fast, stays in the magic

**Out-of-tool (pixel-level compositing via Figma):**
- Overlay a specific screenshot onto a monitor in the slide
- Add a particular image or photo to a specific location
- Precise text positioning or font changes
- Multi-layer composition work

The Figma export is the escape hatch for pixel-level work.

## Installation

```bash
git clone https://github.com/you/conjure.git
cd conjure
bin/setup    # bundle install, db:create, db:migrate, prompt for API keys
bin/dev      # starts Rails server + Solid Queue, opens browser
```

`bin/setup` handles:
1. `bundle install`
2. Creates the SQLite database and runs migrations
3. Prompts for Nano Banana 2 API key and LLM API key (stores in encrypted credentials)
4. Opens the browser to `localhost:3000`

One `git clone`, one `bin/setup`, one `bin/dev`. No Docker, no Postgres, no Redis, no node_modules.

## License

**MIT.**

Fully open. No restrictions. Fork it, host it, sell it, do whatever you want with it.

## Launch Scope

### Must Have (v0.1)

- **Rails 8 + SQLite + Solid Queue + Hotwire** — `git clone`, `bin/setup`, `bin/dev`, browser opens
- **`bin/setup` onboarding** — Runs bundle, creates DB, prompts for API keys, opens browser
- **Settings screen** — View/update API keys, defaults, storage management
- **Home screen (Workshop)** — Project index with card grid, new project flow, empty state
- **Grimoire library** — Create, edit, duplicate, delete grimoires
- **New project wizard** — Name → grimoire selection → starting point (blank/outline/template)
- **Project workspace** — Four-section sidebar: Grimoire, Incantations, Visions, Final Cut
- **Grimoire section** — Select/switch grimoire, edit theme text, variation count selector, conjuring history
- **Incantations section** — Split view with slide list + editor, add/remove/reorder slides
- **Conjuring model** — Additive generation. Each Conjure creates a new Conjuring record with frozen `grimoire_text` and per-vision `slide_text`. Visions accumulate across runs. Cherry-pick freely.
- **Generation engine** — `conjuring.grimoire_text` + `vision.slide_text` → LLM prompt assembly → Nano Banana 2
- **Background generation** — Solid Queue jobs with Turbo Stream progress updates
- **Visions wall** — Grid of all visions across conjurings with gold glow selection, conjuring badges, provenance panel
- **Partial conjuring** — Ability to conjure only specific slides
- **Final Cut** — Assembly view with refine modal (creates new conjuring) and export
- **Provenance** — Click any vision to see exact grimoire, slide description, and prompt
- **Export** — PDF, Figma (PNG folder), project zip (with full conjuring history)
- **Cost estimate** — Visible before generation, updates based on conjuring scope
- **Storage management** — Disk usage display, delete visions from specific conjurings
- **README** — Examples showing contrasting presentation styles (punk broadcast vs Bauhaus)

### Should Have (v0.2)

- **AI-assisted grimoire creation** — "I just have a vibe, expand it"
- **AI-assisted incantation expansion** — "Expand this description", "Suggest visual approach"
- **Generate incantations from outline** — Paste brain dump → structured slides
- **Grimoire remix** — Switch grimoire on existing project and regenerate (new Conjuring)
- **"Generate more like this" / "Generate more different"** on individual visions
- **"Re-conjure with these exact inputs"** — Take a vision's `slide_text`, `prompt`, and parent `conjuring.grimoire_text` and generate more variations with those same inputs
- **Conjuring timeline** — Visual history of all conjurings in a project, showing what changed between runs
- **Wall filtering** — Filter visions by conjuring, by date range, by selected/unselected
- **Grimoire preview strips** — Cached sample renders showing what each grimoire produces
- **Generation cost tracker** — Show actual spend per conjuring and cumulative per project
- **Project templates** — Pre-built slide sets for conference talk, pitch deck, lightning talk, workshop

### Nice to Have (v0.3+)

- **AI visual approach suggestions** for individual slides
- **Speaker notes generation**
- **Grimoire versioning** — Track changes to a grimoire over time
- **Export to Keynote/Google Slides**

## The Newsletter Post Framing

**The hook:** Lead with the contrast — the punk broadcast deck and the Bauhaus investor deck side by side. Same tool. Same workflow. Different grimoires. People think AI-generated presentations means one generic look. Show them it's about conjuring any visual world you can describe.

**The hero image:** The Figma wall screenshot. Twenty parallel visual universes, one talk.

**The anniversary angle:** "A year ago I released MonkeysPaw, a web framework where the pages were wishes. People said it was fun but impractical. They were right. So I made it practical."

**The experience pitch:** "I described my talk in plain English, chose a visual world, and watched entire slides materialize. Then I switched the grimoire and watched the same talk appear in a completely different aesthetic. The creative act shifted from constructing slides to curating visions."

**The tech pitch (for the Ruby audience):** "It's a Rails 8 app with SQLite and Hotwire. No React, no build step, no node_modules. `git clone`, `bin/setup`, `bin/dev`. Generation runs in Solid Queue jobs and pushes progress to the browser via Turbo Streams."

**The call to action:** Here's the repo. `git clone`, `bin/setup`, `bin/dev`. Bring your own API key. Go conjure a presentation. Share what you make.

**The bar test:** Someone uses Conjure, gives a talk next week, and their coworker asks how they made those slides. The answer isn't "I used a tool." It's "I described the vibe I wanted, summoned twenty parallel versions of every slide, and walked through them like a gallery curator picking my favorites." That's the story. That's the spaceship.
