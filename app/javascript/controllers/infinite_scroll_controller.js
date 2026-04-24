import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sentinel"]
  static values = { loading: { type: Boolean, default: false } }

  connect() {
    this.observer = new IntersectionObserver(
      entries => this.handleIntersection(entries),
      { rootMargin: "400px" }
    )
    if (this.hasSentinelTarget) this.observer.observe(this.sentinelTarget)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  sentinelTargetConnected(el) {
    this.observer.observe(el)
  }

  sentinelTargetDisconnected(el) {
    this.observer.unobserve(el)
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) this.loadMore(entry.target)
    })
  }

  async loadMore(sentinel) {
    if (this.loadingValue) return
    const url = sentinel.dataset.nextUrl
    if (!url) return

    this.loadingValue = true
    sentinel.setAttribute("data-loading", "true")

    try {
      const response = await fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: "same-origin"
      })
      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (e) {
      // network error — leave sentinel in place so user can retry by scrolling
      console.warn("[infinite-scroll] fetch failed", e)
    } finally {
      this.loadingValue = false
    }
  }
}
