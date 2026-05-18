import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  toggle() {
    this.dropdownTarget.classList.toggle("hidden")
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  connect() {
    this.boundClose = this.close.bind(this)
    document.addEventListener("click", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }
}
