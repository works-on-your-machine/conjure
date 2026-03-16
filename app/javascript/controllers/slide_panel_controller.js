import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapsed", "expanded", "toggleBtn", "grid"]
  static values = { open: Boolean }

  connect() {
    // Watch the grid for new visions arriving via Turbo Stream
    if (this.hasGridTarget) {
      this.observer = new MutationObserver((mutations) => {
        for (const mutation of mutations) {
          if (mutation.addedNodes.length > 0) {
            // New vision appeared — auto-expand so user can see it
            this.openValue = true
            break
          }
        }
      })
      this.observer.observe(this.gridTarget, { childList: true })
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    if (this.hasCollapsedTarget && this.hasExpandedTarget) {
      if (this.openValue) {
        this.collapsedTarget.classList.add("hidden")
        this.expandedTarget.classList.remove("hidden")
      } else {
        this.collapsedTarget.classList.remove("hidden")
        this.expandedTarget.classList.add("hidden")
      }
    }
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.textContent = this.openValue ? "Collapse" : "Show all"
    }
  }
}
