import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "generating"]

  open() {
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.classList.add("flex")
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("flex")
  }

  submit() {
    // Swap form content for generating state
    if (this.hasFormTarget && this.hasGeneratingTarget) {
      this.formTarget.classList.add("hidden")
      this.generatingTarget.classList.remove("hidden")
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
