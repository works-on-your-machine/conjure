import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapsed", "expanded", "toggleBtn"]
  static values = { collapsed: Boolean }

  toggle() {
    this.collapsedValue = !this.collapsedValue
    this.updateVisibility()
  }

  collapsedValueChanged() {
    this.updateVisibility()
  }

  updateVisibility() {
    if (this.collapsedValue) {
      if (this.hasCollapsedTarget) this.collapsedTarget.classList.remove("hidden")
      if (this.hasExpandedTarget) this.expandedTarget.classList.add("hidden")
      if (this.hasToggleBtnTarget) this.toggleBtnTarget.textContent = "Show all"
    } else {
      if (this.hasCollapsedTarget) this.collapsedTarget.classList.add("hidden")
      if (this.hasExpandedTarget) this.expandedTarget.classList.remove("hidden")
      if (this.hasToggleBtnTarget) this.toggleBtnTarget.textContent = "Collapse"
    }
  }
}
