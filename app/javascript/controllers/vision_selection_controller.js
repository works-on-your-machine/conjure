import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, selected: Boolean }

  toggle() {
    const newSelected = !this.selectedValue
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify({ vision: { selected: newSelected } })
    }).then(() => {
      // Optimistic UI update
      this.selectedValue = newSelected
      this.updateAppearance()
    })
  }

  updateAppearance() {
    const el = this.element
    if (this.selectedValue) {
      el.classList.remove("border", "border-white/5")
      el.classList.add("border-2", "border-gold", "shadow-[0_0_24px_var(--color-gold-glow-strong)]", "scale-[1.02]")
      // Add badge if not present
      if (!el.querySelector("[data-vision-selection-target='badge']")) {
        const badge = document.createElement("div")
        badge.className = "absolute top-1.5 right-1.5 w-5 h-5 rounded-full bg-gold flex items-center justify-center text-[11px] text-plum-deep font-semibold"
        badge.dataset.visionSelectionTarget = "badge"
        badge.textContent = "✦"
        el.appendChild(badge)
      }
    } else {
      el.classList.remove("border-2", "border-gold", "shadow-[0_0_24px_var(--color-gold-glow-strong)]", "scale-[1.02]")
      el.classList.add("border", "border-white/5")
      // Remove badge
      const badge = el.querySelector("[data-vision-selection-target='badge']")
      if (badge) badge.remove()
    }
  }
}
