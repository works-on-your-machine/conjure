import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]
  static classes = ["active", "inactive"]

  select(event) {
    const clickedItem = event.currentTarget

    this.itemTargets.forEach(item => {
      if (item === clickedItem) {
        item.classList.remove(...this.inactiveClasses)
        item.classList.add(...this.activeClasses)
      } else {
        item.classList.remove(...this.activeClasses)
        item.classList.add(...this.inactiveClasses)
      }
    })

    // Update URL with selected slide so refresh preserves position
    const href = clickedItem.getAttribute("href")
    if (href) {
      const slideId = href.match(/slides\/(\d+)/)?.[1]
      if (slideId) {
        const url = new URL(window.location)
        url.searchParams.set("slide", slideId)
        history.replaceState({}, "", url)
      }
    }
  }
}
