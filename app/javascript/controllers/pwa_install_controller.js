import { Controller } from "@hotwired/stimulus"

const SNOOZE_KEY = "pwa-install-remind-at"
const SNOOZE_MS = 3 * 24 * 60 * 60 * 1000

export default class extends Controller {
  static targets = ["stickyBar", "overlay", "instructions"]

  connect() {
    if (this.isStandalone()) return

    localStorage.removeItem("pwa-install-dismissed")

    if (this.isSnoozed()) return

    this.deferredPrompt = null
    this.platform = this.detectPlatform()

    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferredPrompt = e
      this.showStickyBar()
    })

    window.addEventListener("appinstalled", () => {
      this.deferredPrompt = null
      this.hideStickyBar()
      this.hideNavButtons()
    })

    // On browsers without beforeinstallprompt (iOS, Firefox),
    // show the sticky bar after a short delay
    setTimeout(() => {
      if (!this.deferredPrompt) {
        this.showStickyBar()
      }
    }, 2000)
  }

  install() {
    if (this.deferredPrompt) {
      // Android Chrome — directly trigger native install
      this.deferredPrompt.prompt()
      this.deferredPrompt.userChoice.then(() => {
        this.deferredPrompt = null
      })
    } else {
      // iOS / other — show instructions overlay
      this.showInstructions()
    }
  }

  showStickyBar() {
    if (this.isStandalone() || this.isSnoozed()) return
    if (this.hasStickyBarTarget) {
      this.stickyBarTarget.classList.remove("hidden")
    }
  }

  hideStickyBar() {
    if (this.hasStickyBarTarget) {
      this.stickyBarTarget.classList.add("hidden")
    }
  }

  showInstructions() {
    if (!this.hasOverlayTarget || !this.hasInstructionsTarget) return

    const steps = this.getSteps(this.platform)
    if (!steps) return

    this.instructionsTarget.innerHTML = this.buildStepsHTML(steps.title, steps.items)
    this.overlayTarget.classList.remove("hidden")
  }

  closeOverlay() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
  }

  remindLater() {
    localStorage.setItem(SNOOZE_KEY, (Date.now() + SNOOZE_MS).toString())
    this.hideStickyBar()
    this.closeOverlay()
  }

  stopPropagation(e) {
    e.stopPropagation()
  }

  // ── Helpers ──────────────────────────────────────────────

  isSnoozed() {
    const t = localStorage.getItem(SNOOZE_KEY)
    return t && Date.now() < parseInt(t, 10)
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
  }

  hideNavButtons() {
    document.querySelectorAll("[data-pwa-install-btn]").forEach(b => b.style.display = "none")
  }

  detectPlatform() {
    const ua = navigator.userAgent
    const isIOS = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)

    if (isIOS) {
      if (/CriOS|FxiOS/.test(ua)) return { platform: "ios", browser: "other" }
      return { platform: "ios", browser: "safari" }
    }

    if (/SamsungBrowser/.test(ua)) return { platform: "android", browser: "samsung" }
    if (/OPR|Opera/.test(ua)) return { platform: "android", browser: "opera" }
    if (/Firefox/.test(ua)) return { platform: "android", browser: "firefox" }
    return { platform: "android", browser: "chrome" }
  }

  getSteps({ platform, browser }) {
    const t = (key) => this.element.dataset[key] || key

    if (platform === "ios") {
      if (browser === "safari") {
        return {
          title: t("iosTitle"),
          items: [
            { emoji: "⬆️", text: t("iosSafari1") },
            { emoji: "➕", text: t("iosSafari2") },
            { emoji: "✅", text: t("iosSafari3") }
          ]
        }
      }
      return {
        title: t("iosOtherTitle"),
        items: [{ emoji: "🌐", text: t("iosOther1") }]
      }
    }

    if (platform === "android") {
      if (browser === "firefox") {
        return {
          title: t("androidTitle"),
          items: [
            { emoji: "⋮", text: t("firefoxAndroid1") },
            { emoji: "📲", text: t("firefoxAndroid2") }
          ]
        }
      }
      if (browser === "samsung") {
        return {
          title: t("androidTitle"),
          items: [
            { emoji: "☰", text: t("samsungAndroid1") },
            { emoji: "📲", text: t("samsungAndroid2") }
          ]
        }
      }
      if (browser === "opera") {
        return {
          title: t("androidTitle"),
          items: [
            { emoji: "⋮", text: t("operaAndroid1") },
            { emoji: "📲", text: t("operaAndroid2") }
          ]
        }
      }
    }

    return null
  }

  buildStepsHTML(title, items) {
    const rows = items.map((item, i) =>
      `<div class="flex items-center gap-3 py-2">
        <span class="shrink-0 w-8 h-8 rounded-full gradient-brand text-white flex items-center justify-center text-sm font-bold">${i + 1}</span>
        <span class="text-lg mr-1">${item.emoji}</span>
        <p class="text-sm text-gray-700 font-medium">${item.text}</p>
      </div>`
    ).join("")

    return `<p class="text-sm font-bold text-gray-900 mb-2">${title}</p>${rows}`
  }
}
