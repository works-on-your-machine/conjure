import { Controller } from "@hotwired/stimulus"

// Modal controller — placed on the overlay itself
export default class extends Controller {
  static targets = ["image"]

  close() {
    this.element.classList.add("hidden")
    this.element.classList.remove("flex")
    this.imageTarget.src = ""
  }
}
