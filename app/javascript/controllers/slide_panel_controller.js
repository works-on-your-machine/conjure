import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "toggleBtn"]
  static values = { open: Boolean }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    if (this.hasPanelTarget) {
      if (this.openValue) {
        this.panelTarget.classList.remove("hidden")
      } else {
        this.panelTarget.classList.add("hidden")
      }
    }
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.textContent = this.openValue ? "Hide details" : "Details"
    }
  }
}
