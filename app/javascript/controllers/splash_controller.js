import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]
  static values = { id: Number }

  connect() {
    const key = `splash_dismissed_${this.idValue}`
    const dismissed = localStorage.getItem(key)

    if (dismissed) {
      const dismissedAt = parseInt(dismissed, 10)
      const oneDayMs = 24 * 60 * 60 * 1000
      if (Date.now() - dismissedAt < oneDayMs) {
        this.overlayTarget.remove()
        return
      }
    }

    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    const key = `splash_dismissed_${this.idValue}`
    localStorage.setItem(key, Date.now().toString())

    this.overlayTarget.classList.add("opacity-0")
    setTimeout(() => {
      this.overlayTarget.remove()
    }, 300)
  }
}
