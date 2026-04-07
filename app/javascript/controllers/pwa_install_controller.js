import { Controller } from "@hotwired/stimulus"

const REMIND_DELAY_MS = 3 * 24 * 60 * 60 * 1000 // 3 days
const DISMISS_KEY = "pwa-install-remind-at"

export default class extends Controller {
  static targets = ["banner", "instructions", "nativeButton"]

  connect() {
    if (this.isStandalone()) return

    // Clear legacy permanent-dismiss key from previous version
    localStorage.removeItem("pwa-install-dismissed")

    if (this.isSnoozed()) return

    this.deferredPrompt = null

    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferredPrompt = e
      this.showNativeInstall()
    })

    window.addEventListener("appinstalled", () => this.hideBanner())

    setTimeout(() => this.showBanner(), 3000)
  }

  showBanner() {
    if (this.isStandalone()) return
    if (this.isSnoozed()) return

    const info = this.detectBrowser()
    this.populateInstructions(info)

    this.bannerTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.bannerTarget.classList.add("opacity-100")
      this.bannerTarget.classList.remove("opacity-0")
    })
  }

  showNativeInstall() {
    if (this.hasNativeButtonTarget && this.isSecureContext()) {
      this.nativeButtonTarget.classList.remove("hidden")
      if (this.hasInstructionsTarget) {
        this.instructionsTarget.classList.add("hidden")
      }
    }
    this.showBanner()
  }

  install() {
    if (this.deferredPrompt && this.isSecureContext()) {
      this.deferredPrompt.prompt()
      this.deferredPrompt.userChoice.then(() => {
        this.deferredPrompt = null
        this.hideBanner()
      })
    }
  }

  isSecureContext() {
    return window.isSecureContext || location.protocol === "https:"
  }

  remindLater() {
    const remindAt = Date.now() + REMIND_DELAY_MS
    localStorage.setItem(DISMISS_KEY, remindAt.toString())
    this.hideBanner()
  }

  dismissOverlay(e) {
    if (e.target === this.bannerTarget) {
      this.remindLater()
    }
  }

  stopPropagation(e) {
    e.stopPropagation()
  }

  hideBanner() {
    this.bannerTarget.classList.add("opacity-0")
    this.bannerTarget.classList.remove("opacity-100")
    setTimeout(() => this.bannerTarget.classList.add("hidden"), 300)
  }

  isSnoozed() {
    const remindAt = localStorage.getItem(DISMISS_KEY)
    if (!remindAt) return false
    return Date.now() < parseInt(remindAt, 10)
  }

  detectBrowser() {
    const ua = navigator.userAgent
    const isIOS = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)

    if (isIOS) {
      if (/CriOS/.test(ua)) return { platform: "ios", browser: "chrome" }
      if (/FxiOS/.test(ua)) return { platform: "ios", browser: "firefox" }
      return { platform: "ios", browser: "safari" }
    }

    if (/SamsungBrowser/.test(ua)) return { platform: "android", browser: "samsung" }
    if (/OPR|Opera/.test(ua)) return { platform: "android", browser: "opera" }
    if (/Firefox/.test(ua)) return { platform: "android", browser: "firefox" }
    if (/Chrome/.test(ua)) return { platform: "android", browser: "chrome" }

    return { platform: "other", browser: "unknown" }
  }

  populateInstructions(info) {
    if (!this.hasInstructionsTarget) return

    const el = this.instructionsTarget
    const steps = this.getSteps(info)

    if (!steps) {
      el.classList.add("hidden")
      return
    }

    el.innerHTML = this.buildStepsHTML(steps.title, steps.items)
    el.classList.remove("hidden")

    if (this.hasNativeButtonTarget && !this.deferredPrompt) {
      this.nativeButtonTarget.classList.add("hidden")
    }
  }

  getSteps({ platform, browser }) {
    const t = (key) => this.element.dataset[key] || key

    if (platform === "ios") {
      if (browser === "safari") {
        return {
          title: t("iosTitle"),
          items: [
            { icon: "share", text: t("iosSafari1") },
            { icon: null, text: t("iosSafari2") },
            { icon: null, text: t("iosSafari3") }
          ]
        }
      }
      return {
        title: t("iosOtherTitle"),
        items: [
          { icon: null, text: t("iosOther1") }
        ]
      }
    }

    if (platform === "android") {
      if (browser === "firefox") {
        return {
          title: t("androidTitle"),
          items: [
            { icon: "menu", text: t("firefoxAndroid1") },
            { icon: null, text: t("firefoxAndroid2") }
          ]
        }
      }
      if (browser === "samsung") {
        return {
          title: t("androidTitle"),
          items: [
            { icon: "menu", text: t("samsungAndroid1") },
            { icon: null, text: t("samsungAndroid2") }
          ]
        }
      }
      if (browser === "opera") {
        return {
          title: t("androidTitle"),
          items: [
            { icon: "menu", text: t("operaAndroid1") },
            { icon: null, text: t("operaAndroid2") }
          ]
        }
      }
    }

    return null
  }

  buildStepsHTML(title, items) {
    const shareIcon = `<span class="text-lg">⬆️</span>`
    const menuIcon = `<span class="text-lg">⋮</span>`

    const stepsHTML = items.map((item, i) => {
      let icon = ""
      if (item.icon === "share") icon = ` ${shareIcon} `
      if (item.icon === "menu") icon = ` ${menuIcon} `
      return `<div class="flex items-center gap-3">
        <span class="shrink-0 w-7 h-7 rounded-full gradient-brand text-white flex items-center justify-center text-xs font-bold">${i + 1}</span>
        <p class="text-sm text-gray-700 font-medium">${icon}${item.text}</p>
      </div>`
    }).join("")

    return `<div class="bg-orange-50/80 rounded-2xl p-4 space-y-3 border border-orange-100/60">
      <p class="text-sm font-bold text-orange-800">${title}</p>
      ${stepsHTML}
    </div>`
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
  }
}
