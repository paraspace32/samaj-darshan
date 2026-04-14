import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "city"]

  connect() {
    this._debounceTimer = null
  }

  cityInput() {
    clearTimeout(this._debounceTimer)
    this._debounceTimer = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 400)
  }

  disconnect() {
    clearTimeout(this._debounceTimer)
  }
}
