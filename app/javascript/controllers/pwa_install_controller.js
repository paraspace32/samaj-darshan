import { Controller } from "@hotwired/stimulus"

const SNOOZE_KEY = "pwa-install-remind-at"
const SNOOZE_MS = 60 * 60 * 1000

export default class extends Controller {
  static targets = ["stickyBar", "overlay", "instructions"]

  connect() {
    this.platform = this.detectPlatform()

    if (this.isStandalone()) {
      this.hideNavButtons()
      return
    }

    localStorage.removeItem("pwa-install-dismissed")

    window.__pwaController = this

    this._onBeforeInstall = (e) => {
      e.preventDefault()
      window.__pwaPrompt = e
      this.showStickyBar()
    }

    this._onAppInstalled = () => {
      window.__pwaPrompt = null
      this.hideStickyBar()
      this.hideNavButtons()
    }

    window.addEventListener("beforeinstallprompt", this._onBeforeInstall)
    window.addEventListener("appinstalled", this._onAppInstalled)

    if (window.__pwaPrompt) {
      this.showStickyBar()
    }

    if (!this.isSnoozed()) {
      this._fallbackTimer = setTimeout(() => {
        if (!window.__pwaPrompt) {
          this.showStickyBar()
        }
      }, 2000)
    }
  }

  disconnect() {
    if (this._onBeforeInstall) {
      window.removeEventListener("beforeinstallprompt", this._onBeforeInstall)
    }
    if (this._onAppInstalled) {
      window.removeEventListener("appinstalled", this._onAppInstalled)
    }
    if (this._fallbackTimer) {
      clearTimeout(this._fallbackTimer)
    }
  }

  install() {
    if (window.__pwaPrompt) {
      window.__pwaPrompt.prompt()
      window.__pwaPrompt.userChoice.then(() => {
        window.__pwaPrompt = null
      })
    } else {
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
    document.body.style.overflow = "hidden"
  }

  closeOverlay() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
    document.body.style.overflow = ""
  }

  remindLater() {
    localStorage.setItem(SNOOZE_KEY, (Date.now() + SNOOZE_MS).toString())
    this.hideStickyBar()
    this.closeOverlay()
  }

  stopPropagation(e) {
    e.stopPropagation()
  }

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

    const isIOS = /iPad|iPhone|iPod/.test(ua) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)

    if (isIOS) {
      if (this.isInAppBrowser(ua)) return { platform: "ios", browser: "inapp" }
      if (/CriOS/.test(ua)) return { platform: "ios", browser: "chrome" }
      if (/FxiOS/.test(ua)) return { platform: "ios", browser: "firefox" }
      return { platform: "ios", browser: "safari" }
    }

    if (/SamsungBrowser/.test(ua)) return { platform: "android", browser: "samsung" }
    if (/OPR|Opera/.test(ua)) return { platform: "android", browser: "opera" }
    if (/Firefox/.test(ua)) return { platform: "android", browser: "firefox" }
    return { platform: "android", browser: "chrome" }
  }

  isInAppBrowser(ua) {
    return /FBAN|FBAV|Instagram|Line\/|Twitter|WhatsApp|Snapchat|Telegram/i.test(ua)
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
      // Chrome, Firefox, in-app browsers on iOS all need Safari
      return {
        title: t("iosOtherTitle"),
        items: [
          { emoji: "🔗", text: t("iosOtherCopy") },
          { emoji: "🌐", text: t("iosOtherOpen") },
          { emoji: "⬆️", text: t("iosSafari1") },
          { emoji: "➕", text: t("iosSafari2") }
        ]
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
      return {
        title: t("androidTitle"),
        items: [
          { emoji: "⋮", text: t("chromeAndroid1") },
          { emoji: "📲", text: t("chromeAndroid2") }
        ]
      }
    }

    return {
      title: t("androidTitle"),
      items: [
        { emoji: "⋮", text: t("chromeAndroid1") },
        { emoji: "📲", text: t("chromeAndroid2") }
      ]
    }
  }

  buildStepsHTML(title, items) {
    const copyBtn = (this.platform.platform === "ios" && this.platform.browser !== "safari")
      ? `<button onclick="navigator.clipboard.writeText(location.href).then(function(){this.textContent='✅ कॉपी हो गया!'}.bind(this))"
          class="w-full mt-2 mb-1 py-2 rounded-lg bg-orange-50 text-orange-600 text-sm font-bold active:scale-95 transition-transform cursor-pointer border border-orange-200">
          📋 लिंक कॉपी करें
        </button>`
      : ""

    const rows = items.map((item, i) =>
      `<div class="flex items-start gap-3 py-2">
        <span class="shrink-0 w-8 h-8 rounded-full gradient-brand text-white flex items-center justify-center text-sm font-bold">${i + 1}</span>
        <div class="flex items-center gap-2 pt-1">
          <span class="text-lg">${item.emoji}</span>
          <p class="text-sm text-gray-700 font-medium">${item.text}</p>
        </div>
      </div>`
    ).join("")

    return `<p class="text-sm font-bold text-gray-900 mb-2">${title}</p>${copyBtn}${rows}`
  }
}
