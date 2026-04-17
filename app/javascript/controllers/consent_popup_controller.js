import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    // Small delay so the page renders before the modal appears
    setTimeout(() => {
      this.overlayTarget.classList.remove("hidden")
      this.overlayTarget.classList.add("flex")
    }, 400)
  }

  dismiss() {
    this.overlayTarget.classList.add("opacity-0")
    setTimeout(() => this.overlayTarget.classList.add("hidden"), 250)
  }
}
