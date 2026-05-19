import { Controller } from "@hotwired/stimulus"

const FREE_VIEWS = 2
const STORAGE_KEY = "sd_article_views"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    const views = this.getViews()
    const currentPath = window.location.pathname

    if (!this.isAlreadyCounted(currentPath)) {
      this.addView(currentPath)
    }

    if (this.getViews().length > FREE_VIEWS) {
      this.showGate()
    }
  }

  getViews() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]")
    } catch {
      return []
    }
  }

  isAlreadyCounted(path) {
    return this.getViews().includes(path)
  }

  addView(path) {
    const views = this.getViews()
    views.push(path)
    localStorage.setItem(STORAGE_KEY, JSON.stringify(views))
  }

  showGate() {
    if (!this.hasOverlayTarget) return
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }
}
