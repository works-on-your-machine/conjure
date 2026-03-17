import { Controller } from "@hotwired/stimulus"

// Toggles the summoning reveal animation on/off via localStorage.
export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    const enabled = localStorage.getItem("conjure-reveal") !== "false"
    this.checkboxTarget.checked = enabled
  }

  toggle() {
    localStorage.setItem("conjure-reveal", this.checkboxTarget.checked ? "true" : "false")
  }
}
