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

### ~~1. The Conjure CTA is missing from the sidebar~~ DONE

Added persistent "✦ Conjure" button with variations dropdown and live cost estimate to the sidebar. Controller accepts variations param. Cost rate updated to $0.08/image (~20% buffer over actual $0.067 at 1024px).

### ~~2. Project card thumbnails are permanently dead~~ DONE

Mosaic now shows up to 4 real vision images (selected first, then complete). Falls back to gray boxes only when no visions exist. Eager-loads attachments to avoid N+1.

### ~~3. Two gold CTAs competing on the Visions page~~ DONE

Demoted "View assembly" to secondary style (surface bg, border, muted text). "✦ Conjure" is now the sole gold CTA on the Visions page.

### 4. No responsive behavior at all — SKIPPED

Desktop/laptop-only tool. Not a priority.

### ~~5. Empty states are inconsistent across sections~~ DONE

All three workspace sections now use the shared `_empty_state` component with on-brand copy and CTAs: Incantations (no slides), Visions (no slides / no visions), Grimoire (no grimoires).

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
