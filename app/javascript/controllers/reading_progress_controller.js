import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar"]

  connect() {
    this.bound = this.update.bind(this)
    window.addEventListener("scroll", this.bound, { passive: true })
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.bound)
  }

  update() {
    const scrolled = window.scrollY
    const total = document.documentElement.scrollHeight - window.innerHeight
    const pct = total > 0 ? Math.min((scrolled / total) * 100, 100) : 0
    this.barTarget.style.width = pct + "%"
  }
}
