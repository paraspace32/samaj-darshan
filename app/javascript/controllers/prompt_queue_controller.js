import { Controller } from "@hotwired/stimulus"

// Sequences popups so only one shows at a time: Login → PWA → Push.
// Each prompt waits for the previous to be dismissed or completed.
//
// Usage: attach to body or a wrapper element
//   data-controller="prompt-queue"
//
// Each child prompt registers via data-prompt-queue-target with a priority.
// This controller decides WHEN to show each one.

const QUEUE_DELAY = 5000         // ms before first prompt
const BETWEEN_DELAY = 10000      // ms between prompts
const LOGIN_COOLDOWN = 3 * 24 * 60 * 60 * 1000  // 3 days

export default class extends Controller {
  static values = {
    loggedIn: Boolean,
    pwaInstalled: Boolean,
    pushSubscribed: Boolean
  }

  connect() {
    this.queue = []
    this.active = null

    // Build the queue based on what the user hasn't done yet
    if (!this.loggedInValue && !this.isDismissed("login_prompt")) {
      this.queue.push("login")
    }

    if (!this.pwaInstalledValue && !this.isPwaStandalone()) {
      this.queue.push("pwa")
    }

    if (!this.pushSubscribedValue && this.pushSupported() && !this.isPushDone()) {
      this.queue.push("push")
    }

    if (this.queue.length > 0) {
      this._timer = setTimeout(() => this.showNext(), QUEUE_DELAY)
    }

    // Listen for dismiss events from child prompts
    this._onDismiss = (e) => this.onPromptDismissed(e.detail?.type)
    document.addEventListener("prompt:dismissed", this._onDismiss)
    document.addEventListener("push:subscribed", () => this.onPromptDismissed("push"))
  }

  disconnect() {
    if (this._timer) clearTimeout(this._timer)
    if (this._betweenTimer) clearTimeout(this._betweenTimer)
    document.removeEventListener("prompt:dismissed", this._onDismiss)
  }

  showNext() {
    if (this.queue.length === 0) return

    const type = this.queue.shift()
    this.active = type

    if (type === "login") {
      this.showElement("prompt-login-bar")
    } else if (type === "pwa") {
      // Trigger the existing PWA banner
      const bar = document.getElementById("pwa-sticky-bar")
      if (bar) {
        bar.classList.remove("hidden")
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            bar.classList.remove("translate-y-4", "opacity-0")
          })
        })
      }
    } else if (type === "push") {
      const bar = document.getElementById("push-bar")
      if (bar) {
        bar.classList.remove("hidden")
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            bar.classList.remove("translate-y-4", "opacity-0")
          })
        })
      }
    }
  }

  onPromptDismissed(type) {
    if (type === this.active) {
      this.active = null
      if (this.queue.length > 0) {
        this._betweenTimer = setTimeout(() => this.showNext(), BETWEEN_DELAY)
      }
    }
  }

  showElement(id) {
    const el = document.getElementById(id)
    if (!el) return
    el.classList.remove("hidden")
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        el.classList.remove("translate-y-4", "opacity-0")
      })
    })
  }

  isDismissed(key) {
    const t = parseInt(localStorage.getItem(key) || "0")
    return t && (Date.now() - t < LOGIN_COOLDOWN)
  }

  isPwaStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
  }

  pushSupported() {
    return "Notification" in window && "serviceWorker" in navigator
  }

  isPushDone() {
    return localStorage.getItem("fcm_subscribed") === "true" ||
      (typeof Notification !== "undefined" && Notification.permission === "granted")
  }
}
