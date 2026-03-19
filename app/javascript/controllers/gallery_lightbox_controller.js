import { Controller } from "@hotwired/stimulus"

// Gallery lightbox for cycling through visions within a slide.
// Scoped to the visions page wrapper so it can read data attributes
// from vision tiles and manage the overlay targets.
export default class extends Controller {
  static targets = ["overlay", "image", "caption", "counter", "selectButton"]

  connect() {
    this.visions = []
    this.currentIndex = 0
    this.boundKeyHandler = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeyHandler)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    } else if (event.key === "ArrowLeft") {
      this.previous()
    } else if (event.key === "ArrowRight") {
      this.next()
    }
  }

  openToVision({ params: { visionId, slideId } }) {
    this.visions = this.buildVisionList(slideId)
    if (this.visions.length === 0) return

    const index = this.visions.findIndex(v => v.id === visionId)
    this.currentIndex = index >= 0 ? index : 0

    this.show()
    this.render()
    this.preloadAdjacent()
    document.addEventListener("keydown", this.boundKeyHandler)
  }

  next(event) {
    if (event) event.stopPropagation()
    if (this.visions.length === 0) return
    this.currentIndex = (this.currentIndex + 1) % this.visions.length
    this.render()
    this.preloadAdjacent()
  }

  previous(event) {
    if (event) event.stopPropagation()
    if (this.visions.length === 0) return
    this.currentIndex = (this.currentIndex - 1 + this.visions.length) % this.visions.length
    this.render()
    this.preloadAdjacent()
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
    this.imageTarget.src = ""
    this.visions = []
    document.removeEventListener("keydown", this.boundKeyHandler)
  }

  closeOnBackground(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  async toggleSelect(event) {
    event.stopPropagation()
    const vision = this.visions[this.currentIndex]
    if (!vision) return

    const newSelected = !vision.selected
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(vision.selectUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken
        },
        body: new URLSearchParams({
          "vision[selected]": newSelected,
          "open_slide": vision.slideId
        })
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)

        // When selecting, deselect all others in the local list
        if (newSelected) {
          this.visions.forEach(v => v.selected = false)
        }
        vision.selected = newSelected

        this.renderSelectButton()
      }
    } catch (e) {
      // Silently fail — the background state is unchanged
    }
  }

  // --- Private ---

  buildVisionList(slideId) {
    const grid = document.getElementById(`slide_${slideId}_visions`)
    if (!grid) return []

    const tiles = grid.querySelectorAll("[data-vision-id]")
    const visions = []

    tiles.forEach(tile => {
      const src = tile.dataset.visionSrc
      if (!src) return // skip visions without images

      visions.push({
        id: parseInt(tile.dataset.visionId),
        src: src,
        slideId: tile.dataset.visionSlideId,
        slideTitle: tile.dataset.visionSlideTitle,
        position: tile.dataset.visionPosition,
        conjuringId: tile.dataset.visionConjuringId,
        selected: tile.dataset.visionSelected === "true",
        selectUrl: tile.dataset.visionSelectUrl
      })
    })

    return visions
  }

  show() {
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
  }

  render() {
    const vision = this.visions[this.currentIndex]
    if (!vision) return

    this.imageTarget.src = vision.src
    this.captionTarget.textContent = `${vision.slideTitle} — variation ${vision.position}, Run ${vision.conjuringId}`
    this.counterTarget.textContent = `${this.currentIndex + 1} of ${this.visions.length}`
    this.renderSelectButton()
  }

  renderSelectButton() {
    const vision = this.visions[this.currentIndex]
    if (!vision || !this.hasSelectButtonTarget) return

    if (vision.selected) {
      this.selectButtonTarget.textContent = "✦ Selected"
      this.selectButtonTarget.classList.add("bg-gold", "text-plum-deep", "border-gold")
      this.selectButtonTarget.classList.remove("bg-surface", "text-gold", "border-gold-dim")
    } else {
      this.selectButtonTarget.textContent = "✦ Select"
      this.selectButtonTarget.classList.remove("bg-gold", "text-plum-deep", "border-gold")
      this.selectButtonTarget.classList.add("bg-surface", "text-gold", "border-gold-dim")
    }
  }

  preloadAdjacent() {
    const prevIdx = (this.currentIndex - 1 + this.visions.length) % this.visions.length
    const nextIdx = (this.currentIndex + 1) % this.visions.length

    if (this.visions[prevIdx]) new Image().src = this.visions[prevIdx].src
    if (this.visions[nextIdx]) new Image().src = this.visions[nextIdx].src
  }
}
