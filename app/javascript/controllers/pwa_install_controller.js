import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner", "instructions", "nativeButton"]

  connect() {
    if (this.isStandalone()) return
    if (localStorage.getItem("pwa-install-dismissed")) return

    this.deferredPrompt = null

    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferredPrompt = e
      this.showNativeInstall()
    })

    window.addEventListener("appinstalled", () => this.hideBanner())

    setTimeout(() => this.showBanner(), 2000)
  }

  showBanner() {
    if (this.isStandalone()) return
    if (localStorage.getItem("pwa-install-dismissed")) return

    const info = this.detectBrowser()
    this.populateInstructions(info)

    this.bannerTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.bannerTarget.classList.add("pwa-banner-visible")
    })
  }

  showNativeInstall() {
    if (this.hasNativeButtonTarget) {
      this.nativeButtonTarget.classList.remove("hidden")
    }
    if (this.hasInstructionsTarget) {
      this.instructionsTarget.classList.add("hidden")
    }
    this.showBanner()
  }

  install() {
    if (this.deferredPrompt) {
      this.deferredPrompt.prompt()
      this.deferredPrompt.userChoice.then(() => {
        this.deferredPrompt = null
        this.hideBanner()
      })
    }
  }

  dismiss() {
    localStorage.setItem("pwa-install-dismissed", "1")
    this.hideBanner()
  }

  hideBanner() {
    this.bannerTarget.classList.remove("pwa-banner-visible")
    setTimeout(() => this.bannerTarget.classList.add("hidden"), 300)
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
          { icon: null, text: t("iosOther1") },
          { icon: "share", text: t("iosSafari1") },
          { icon: null, text: t("iosSafari2") },
          { icon: null, text: t("iosSafari3") }
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
    const shareIcon = `<svg class="inline-block w-4 h-4 -mt-0.5 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"/></svg>`
    const menuIcon = `<svg class="inline-block w-4 h-4 -mt-0.5 text-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>`

    const stepsHTML = items.map((item, i) => {
      let icon = ""
      if (item.icon === "share") icon = ` ${shareIcon} `
      if (item.icon === "menu") icon = ` ${menuIcon} `
      return `<div class="flex items-start gap-2">
        <span class="shrink-0 w-5 h-5 rounded-full bg-orange-200 text-orange-700 flex items-center justify-center text-[10px] font-bold mt-0.5">${i + 1}</span>
        <p class="text-xs text-orange-700">${icon}${item.text}</p>
      </div>`
    }).join("")

    return `<div class="bg-orange-50 rounded-xl p-3 space-y-2">
      <p class="text-xs font-semibold text-orange-800">${title}</p>
      ${stepsHTML}
    </div>`
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
  }
}
