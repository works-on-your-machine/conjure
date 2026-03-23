import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "image", "title", "slideIdField", "sourceVisionIdField", "refinementField", "redirectField"]

  open(event) {
    event.preventDefault()
    const { slideId, slideTitle, imageUrl, sourceVisionId, redirectTo } = event.params

    this.slideIdFieldTarget.value = slideId
    this.sourceVisionIdFieldTarget.value = sourceVisionId
    this.titleTarget.textContent = `Refine: ${slideTitle}`
    this.imageTarget.src = imageUrl
    this.redirectFieldTarget.value = redirectTo || "stay"
    this.refinementFieldTarget.value = ""
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
  }

  // Close modal after form submission — turbo stream broadcasts handle the vision update
  submitted() {
    this.close()
  }

  close(event) {
    if (event) event.preventDefault()
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
  }

  closeOnBackground(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }
}
