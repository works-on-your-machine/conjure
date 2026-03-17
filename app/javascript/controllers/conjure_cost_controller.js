import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["variations", "cost"]
  static values = { slides: Number, rate: { type: Number, default: 0.04 } }

  connect() {
    this.update()
  }

  update() {
    const variations = parseInt(this.variationsTarget.value) || 0
    const cost = (this.slidesValue * variations * this.rateValue).toFixed(2)
    this.costTarget.textContent = `${this.slidesValue} slides × ${variations} var ≈ $${cost}`
  }
}
