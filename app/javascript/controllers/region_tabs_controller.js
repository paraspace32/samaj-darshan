import { Controller } from "@hotwired/stimulus"

// Handles region tab active-state highlighting + scroll-to-content.
// Turbo Frame takes care of loading the news content; this controller
// updates the visual active class immediately on click and then scrolls
// the region-news frame into view once the frame finishes loading.
//
// Usage:
//   data-controller="region-tabs"  on the tab strip wrapper
//   data-region-tabs-target="tab"  on each tab link
//   data-action="region-tabs#select" on each tab link
export default class extends Controller {
  static targets = ["tab"]

  connect() {
    // Listen for the turbo-frame load event so we can scroll after content arrives
    this._frameLoadHandler = this._onFrameLoad.bind(this)
    document.addEventListener("turbo:frame-load", this._frameLoadHandler)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this._frameLoadHandler)
  }

  select(event) {
    this.tabTargets.forEach(t => t.classList.remove("region-tab-active"))
    event.currentTarget.classList.add("region-tab-active")
    this._pendingScroll = true
  }

  _onFrameLoad(event) {
    if (!this._pendingScroll) return
    if (event.target?.id !== "region-news") return
    this._pendingScroll = false

    const frame = document.getElementById("region-news")
    if (!frame) return

    // Scroll so the region section sits just below the sticky header (~64px)
    const top = frame.getBoundingClientRect().top + window.scrollY - 72
    window.scrollTo({ top, behavior: "smooth" })
  }
}
