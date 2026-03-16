import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapsed", "expanded", "toggleBtn"]
  static values = { open: Boolean }

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
