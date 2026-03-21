import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.timeout = null
  }

  save() {
    clearTimeout(this.timeout)
    this.statusTarget.textContent = "Saving..."
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 800)
  }

  showSaved() {
    this.statusTarget.textContent = "Saved \u2713"
    clearTimeout(this.fadeTimeout)
    this.fadeTimeout = setTimeout(() => {
      this.statusTarget.textContent = ""
    }, 2000)
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearTimeout(this.fadeTimeout)
  }
}
