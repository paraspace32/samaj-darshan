import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "label"]

  copy() {
    const text = this.sourceTarget.value
    navigator.clipboard.writeText(text).then(() => {
      const original = this.labelTarget.textContent
      this.labelTarget.textContent = "Copied!"
      setTimeout(() => { this.labelTarget.textContent = original }, 2000)
    })
  }
}
