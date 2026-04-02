import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  toggle() {
    const isHidden = this.sidebarTarget.classList.contains("-translate-x-full")
    if (isHidden) {
      this.sidebarTarget.classList.remove("-translate-x-full")
      this.overlayTarget.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    } else {
      this.close()
    }
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
}
