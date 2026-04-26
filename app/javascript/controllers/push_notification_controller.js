import { Controller } from "@hotwired/stimulus"

// Handles web push notification permission + FCM token registration.
//
// Usage on element:
//   data-controller="push-notification"
//   data-push-notification-vapid-key-value="<%= firebase_vapid_key %>"
//   data-push-notification-config-value='<%= firebase_config_json %>'
//   data-push-notification-save-url-value="<%= push_subscription_path %>"
export default class extends Controller {
  static values = {
    vapidKey: String,
    config:   String,   // JSON string of Firebase web config
    saveUrl:  String
  }

  static targets = ["button", "status"]

  connect() {
    if (!this.supported) return
    this.checkCurrentPermission()
  }

  get supported() {
    return "Notification" in window && "serviceWorker" in navigator && this.vapidKeyValue
  }

  checkCurrentPermission() {
    if (Notification.permission === "granted") {
      // Already allowed — register token silently, no UI needed
      this.registerToken()
    } else if (Notification.permission === "denied") {
      this.showStatus("blocked")
    }
    // default → bar is shown by the inline script; button triggers subscribe()
  }

  // Called by the subscribe button (permission=default case only)
  async subscribe() {
    if (!this.supported) return

    try {
      const permission = await Notification.requestPermission()
      if (permission === "granted") {
        await this.registerToken()
        this.showStatus("subscribed")
        if (typeof dismissPushBar === "function") dismissPushBar()
      } else {
        this.showStatus("blocked")
      }
    } catch (err) {
      console.error("[PushNotification] permission error:", err)
    }
  }

  async registerToken() {
    if (this._registering) return
    this._registering = true
    try {
      const config = JSON.parse(this.configValue)

      // Dynamically import Firebase from CDN (works with importmap)
      const { initializeApp, getApps } = await import("https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js")
      const { getMessaging, getToken }  = await import("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging.js")

      // Avoid double-initialising Firebase app
      const app       = getApps().length ? getApps()[0] : initializeApp(config)
      const messaging = getMessaging(app)

      // Reuse the already-registered merged SW (registered on page load in layout)
      // Falls back to registering if somehow not yet active
      let swReg = await navigator.serviceWorker.getRegistration("/")
      if (!swReg) {
        swReg = await navigator.serviceWorker.register("/firebase-messaging-sw.js", { scope: "/" })
      }
      await navigator.serviceWorker.ready

      const token = await getToken(messaging, {
        vapidKey:                    this.vapidKeyValue,
        serviceWorkerRegistration:   swReg
      })

      if (token) {
        await this.saveToken(token)
      } else {
        this._reportError("getToken returned empty", `vapidKey length: ${this.vapidKeyValue?.length}, swState: ${swReg?.active?.state}`)
      }
    } catch (err) {
      console.error("[PushNotification] registerToken error:", err)
      this._reportError(err.message || String(err), err.stack?.slice(0, 300) || "")
    } finally {
      this._registering = false
    }
  }

  async _reportError(message, detail) {
    try {
      const csrf = document.querySelector('meta[name="csrf-token"]')?.content
      await fetch("/push_subscription/log_error", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf || "" },
        body: JSON.stringify({ message, detail })
      })
    } catch (_) { /* best-effort */ }
  }

  async saveToken(token) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(this.saveUrlValue, {
      method:  "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken || ""
      },
      body: JSON.stringify({
        token:        token,
        platform:     this._detectPlatform(),
        display_mode: this._detectDisplayMode(),
        os:           this._detectOS(),
        browser:      navigator.userAgent.slice(0, 200)
      })
    })
    if (!response.ok) {
      throw new Error(`[PushNotification] Failed to save token: ${response.status}`)
    }
    localStorage.setItem("fcm_subscribed", "true")
  }

  // ── Detection helpers ───────────────────────────────────────────────────────

  // "pwa" when launched from home screen / app drawer (standalone display mode).
  // "web" when opened in a regular browser tab.
  _detectPlatform() {
    return this._isStandalone() ? "pwa" : "web"
  }

  // "standalone" = installed PWA, "browser" = regular tab
  _detectDisplayMode() {
    return this._isStandalone() ? "standalone" : "browser"
  }

  _isStandalone() {
    // Android & desktop Chrome/Edge PWA
    if (window.matchMedia("(display-mode: standalone)").matches) return true
    // iOS Safari "Add to Home Screen"
    if (navigator.standalone === true) return true
    return false
  }

  // Detect OS / device type from the user agent string.
  // Returns one of: android | ios | windows | macos | linux | unknown
  _detectOS() {
    const ua = navigator.userAgent
    if (/android/i.test(ua))              return "android"
    if (/iphone|ipad|ipod/i.test(ua))     return "ios"
    if (/windows/i.test(ua))              return "windows"
    if (/macintosh|mac os x/i.test(ua))   return "macos"
    if (/linux/i.test(ua))                return "linux"
    return "unknown"
  }

  showStatus(state) {
    if (!this.hasButtonTarget) return

    const btn = this.buttonTarget
    if (state === "subscribed") {
      btn.textContent = "🔔 Subscribed"
      btn.disabled    = true
      btn.classList.add("opacity-60", "cursor-default")
    } else if (state === "blocked") {
      btn.textContent = "🔕 Blocked in browser"
      btn.disabled    = true
      btn.classList.add("opacity-60", "cursor-default")
    }
    // "prompt" → leave button as-is (enable notifications)
  }
}
