# Design Critique: Conjure

## Anti-Patterns Verdict: PASS (with one flag)

This does **not** look AI-generated. The design has a genuine point of view. No gradient text, no glassmorphism, no neon glow accents, no hero metric cards, no generic Inter/Poppins font stack. The plum-and-gold palette is distinctive, the Cormorant Garamond + DM Sans pairing is an intentional choice that reinforces the arcane brand, and the ✦ motif is used as a real brand element rather than decoration.

**One flag:** The dark-mode-with-glowing-accent-color pattern *is* increasingly associated with AI-generated work, but Conjure earns it through the thematic commitment. The gold glow reads as "candlelit spellbook," not "SaaS landing page." You're fine.

## Overall Impression

Conjure has a strong identity and a clearly designed visual language. The magical vocabulary (Grimoire, Incantation, Vision, Conjure) is well-matched by the palette and typography. The workflow architecture (Workshop → Grimoire → Incantations → Visions → Assembly) is logical and the sidebar makes navigation intuitive.

**The single biggest opportunity:** The app's primary action — *conjuring visions* — is buried inside a subsection form. The React prototype puts a large "✦ Conjure" button at the bottom of the sidebar, always visible. The current implementation hides this behind navigating to the Visions tab and finding the form. This is the core loop of the product and it needs to be accessible from everywhere in the workspace.

## What's Working

1. **Typography hierarchy is excellent.** Cormorant Garamond for display/headings vs DM Sans for UI text creates an immediate visual layer separation. The serif gives every section title gravitas, while the sans-serif stays out of the way for functional elements. The `text-[11px]` metadata, `text-[13px]` body, `text-lg`/`text-2xl` heading progression is consistent across all views.

2. **The vision selection UX is well-crafted.** Selected visions get a gold border + glow + scale bump + ✦ badge. Unselected ones recede. The expand/collapse panel with auto-expand on new Turbo Stream arrivals shows real thought about the generation workflow. The "Provenance details" disclosure is the right call — power users want it, others don't.

3. **The empty state on Workshop** (dashed border, ✦ icon, "Every presentation begins as a vision") is well-written and on-brand. It guides without being patronizing.

## Priority Issues

### 1. The Conjure CTA is missing from the sidebar

**What:** The React prototype shows a persistent "✦ Conjure" button at the bottom of the sidebar — the most important action in the app, always one click away. The implementation only has the cost estimate text (`3 slides × 5 var ≈ $0.60`), no button.

**Why it matters:** Users need to navigate to the Visions section, find the conjure controls bar, configure scope, and then click. That's 3 steps for the action the product is named after. The cost estimate in the sidebar is already doing the mental prep ("here's what it'll cost") — it needs the CTA to close the loop.

**Fix:** Add the "✦ Conjure" button below the cost estimate in `_sidebar.html.erb`. Wire it as a form POST to `project_conjurings_path`.

### 2. Project card thumbnails are permanently dead

**What:** `_project_card.html.erb` renders a 2x2 grid of `bg-surface-light` gray boxes. These are hardcoded placeholders that never show actual vision images. Every project card in the Workshop looks identical from the thumbnail.

**Why it matters:** The card thumbnail is the largest visual element on the home screen. When every card shows the same gray grid, users can't visually distinguish projects at a glance. The project name in 18px serif becomes the only differentiator, which defeats the purpose of a visual tool.

**Fix:** Pull the first 4 selected visions (or any visions) from the project and render their thumbnails in the mosaic. Fall back to the gray grid only when no visions exist. The React prototype's `ProjectMosaic` component does exactly this.

### 3. Two gold CTAs competing on the Visions page

**What:** Both "View assembly (N/M) →" and "✦ Conjure" are styled as gold primary buttons on the Visions view. The Conjure button is actually *larger* (`px-7 py-3 font-display text-base` vs `px-5 py-2.5 text-sm`), but both have the gold glow shadow.

**Why it matters:** When two elements scream "I'm the primary action" equally, neither wins. Users' eyes bounce between them. The Visions page has a clear job: conjure images, then review/select them. "View assembly" is a navigation action (secondary), not the page's purpose.

**Fix:** Demote "View assembly" to the `default` button variant (surface background, border, muted text). Keep "✦ Conjure" as the sole gold CTA on this page.

### 4. No responsive behavior at all

**What:** The sidebar is `w-[200px]`, the incantation pane is `w-[260px]`, content areas are `max-w-[960px]`. No breakpoints, no `@media` queries, no responsive Tailwind classes. On anything below ~768px, the workspace is unusable — the sidebar alone consumes ~50% of the viewport.

**Why it matters:** Even if this is primarily a desktop tool, many users will check projects on tablets or phones. The Workshop/home page is the most likely mobile visit ("let me show someone this project") and it also breaks — 280px card minimums plus 40px padding means single column only below ~640px, with no padding adjustment.

**Fix:** Add responsive breakpoints: collapse sidebar to an icon bar or drawer below `md`, stack the incantation panes vertically, adjust padding. Start with the Workshop and project workspace views.

### 5. Empty states are inconsistent across sections

**What:** Workshop has a beautiful empty state with icon, serif heading, descriptive copy, and CTA. But Incantations shows "Add your first slide using the form on the left" in dim 13px text. Visions shows nothing when there are slides but no visions. The Grimoire section has no empty state if zero grimoires exist (the radio button list is just empty).

**Why it matters:** Empty states are the first thing new users see in each section. Every empty section is a chance to teach the workflow. An empty Visions page should say something like "Conjure visions for your slides" with a CTA, not silently render an empty list.

**Fix:** Apply the `_empty_state.html.erb` pattern to Incantations (no slides), Visions (no visions), and Grimoire (no grimoires). Match the Workshop's quality — icon, title, one sentence, action button.

## Minor Observations

- **Unicode sidebar icons (◈ ◇ ◆ ▣)** are hard to distinguish at 14px. They blur together. SVG icons or a small icon font would be more legible and give you more expressive range.

- **Native `<select>` elements** in Grimoire and Settings look jarring. The white system dropdown arrow against the dark surface breaks the visual language. Consider a custom select component or at minimum `appearance-none` with a styled chevron.

- **The New Project flow lacks the step indicator** shown in the React prototype (1 → 2 → 3 with a progress line). Currently both steps are stacked vertically on one page with no sense of progression. For a two-step form this is fine functionally, but the prototype's version is more polished and makes the "Create project →" button feel earned.

- **No hover state on vision thumbnails beyond a faint border change.** For the primary interactive element of the Visions page, unselected vision thumbnails need more affordance — slight scale, opacity shift, or a "click to select" overlay on hover.

- **The "generating..." pulse animation** is the only loading state. For an app whose core loop involves waiting for AI image generation, this is underserving the moment. A skeleton shimmer, progress percentage, or even a thematic "summoning" animation would transform perceived wait time.

- **Button styles are inlined everywhere** instead of using `_button.html.erb`. The gold CTA class string (`bg-gold text-plum-deep px-6 py-2.5 rounded-md font-body text-sm font-semibold no-underline shadow-[0_4px_20px_var(--color-gold-glow-strong)]`) appears in 10+ places as raw Tailwind. One divergence and you have an inconsistency nobody catches.

## Questions to Consider

- **What if the Conjure button followed you?** A persistent floating CTA or always-visible sidebar button means the user never has to think "where do I go to generate." The app is called *Conjure* — that action should be omnipresent.

- **What would this feel like if the generation wait was *part of the magic*?** Right now "generating..." is a loading state to endure. What if it was a summoning ritual — a slow reveal, arcane symbols dissolving into the image, a brief flash of gold when it materializes? This is your brand moment.

- **Does the Workshop need to be a card grid?** With zero vision thumbnails populating the mosaics, every project card looks nearly identical. Would a list view with richer metadata (last vision generated, completion %, grimoire preview strip) be more useful at this stage?

- **Is the sidebar earning its 200px?** It shows the project name, grimoire, 4 nav links, and a cost estimate. That's a lot of permanent real estate for not much information. Could it be narrower, or collapsible, giving more room to the content areas that matter?
