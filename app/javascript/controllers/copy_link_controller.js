import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  copy() {
    const url = this.urlValue || window.location.href
    navigator.clipboard.writeText(url).then(() => {
      const original = this.element.textContent
      this.element.textContent = "Copied!"
      setTimeout(() => { this.element.textContent = original }, 2000)
    })
  }
}
