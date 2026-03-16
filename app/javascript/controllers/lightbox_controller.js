import { Controller } from "@hotwired/stimulus"

// Trigger controller — placed on the "View full screen" button
export default class extends Controller {
  static values = { src: String }

  open(event) {
    event.stopPropagation()
    const overlay = document.getElementById("lightbox-overlay")
    const image = overlay.querySelector("img")
    image.src = this.srcValue
    overlay.classList.remove("hidden")
    overlay.classList.add("flex")
  }
}
