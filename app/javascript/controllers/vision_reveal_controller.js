import { Controller } from "@hotwired/stimulus"

// Plays a summoning reveal animation when a new vision image arrives.
// Skips animation for visions already on the page at load time.
// Respects a localStorage toggle ("conjure-reveal" = "true"/"false").
export default class extends Controller {
  static values = { revealed: { type: Boolean, default: false } }

  connect() {
    // Already-loaded visions (page render) skip animation
    if (this.revealedValue) return

    // Check if reveal is enabled (default: on)
    if (localStorage.getItem("conjure-reveal") === "false") {
      this.revealedValue = true
      return
    }

    this.playReveal()
  }

  playReveal() {
    const el = this.element
    const overlay = document.createElement("div")
    overlay.className = "vision-reveal-overlay"
    overlay.innerHTML = '<span class="vision-reveal-symbol">✦</span>'
    el.style.position = "relative"
    el.appendChild(overlay)

    // After the animation completes, remove the overlay
    overlay.addEventListener("animationend", () => {
      overlay.remove()
      this.revealedValue = true
    })
  }
}
