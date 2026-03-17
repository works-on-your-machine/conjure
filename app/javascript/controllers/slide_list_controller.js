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
  }
}
