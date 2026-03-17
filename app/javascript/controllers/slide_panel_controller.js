import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapsed", "expanded", "toggleBtn", "grid"]
  static values = { open: Boolean, projectId: Number, slideId: Number }

  initialize() {
    this.initializing = true
  }

  connect() {
    const storedOpenState = this.loadStoredOpenState()
    if (storedOpenState !== null) {
      this.openValue = storedOpenState
    }

    this.render()

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

    this.initializing = false
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
    this.render()

    if (!this.initializing) {
      this.persistOpenState()
    }
  }

  render() {
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

  loadStoredOpenState() {
    if (!this.hasProjectIdValue || !this.hasSlideIdValue) {
      return null
    }

    const openSlides = this.readOpenSlides()
    if (openSlides === null) {
      return null
    }

    return openSlides.includes(this.slideIdValue)
  }

  persistOpenState() {
    if (!this.hasProjectIdValue || !this.hasSlideIdValue) {
      return
    }

    const openSlides = new Set(this.readOpenSlides() || [])

    if (this.openValue) {
      openSlides.add(this.slideIdValue)
    } else {
      openSlides.delete(this.slideIdValue)
    }

    this.writeOpenSlides([...openSlides])
  }

  readOpenSlides() {
    try {
      const storedValue = window.sessionStorage.getItem(this.storageKey())
      return storedValue ? JSON.parse(storedValue) : null
    } catch {
      return null
    }
  }

  writeOpenSlides(slideIds) {
    try {
      window.sessionStorage.setItem(this.storageKey(), JSON.stringify(slideIds))
    } catch {
      // Ignore storage errors and fall back to per-render defaults.
    }
  }

  storageKey() {
    return `project:${this.projectIdValue}:visions:openSlides`
  }
}
