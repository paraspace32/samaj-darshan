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
      this.showStatus("subscribed")
      this.registerToken()     // refresh token silently on each visit
    } else if (Notification.permission === "denied") {
      this.showStatus("blocked")
    } else {
      this.showStatus("prompt")
    }
  }

  // Called by the subscribe button
  async subscribe() {
    if (!this.supported) return

    try {
      const permission = await Notification.requestPermission()
      if (permission === "granted") {
        await this.registerToken()
        this.showStatus("subscribed")
      } else {
        this.showStatus("blocked")
      }
    } catch (err) {
      console.error("[PushNotification] permission error:", err)
    }
  }

  async registerToken() {
    try {
      const config = JSON.parse(this.configValue)

      // Dynamically import Firebase from CDN (works with importmap)
      const { initializeApp, getApps } = await import("https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js")
      const { getMessaging, getToken }  = await import("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging.js")

      // Avoid double-initialising Firebase app
      const app       = getApps().length ? getApps()[0] : initializeApp(config)
      const messaging = getMessaging(app)

      // Register the dedicated Firebase SW
      const swReg = await navigator.serviceWorker.register("/firebase-messaging-sw.js", { scope: "/" })
      await navigator.serviceWorker.ready

      const token = await getToken(messaging, {
        vapidKey:                    this.vapidKeyValue,
        serviceWorkerRegistration:   swReg
      })

      if (token) {
        await this.saveToken(token)
      }
    } catch (err) {
      console.error("[PushNotification] registerToken error:", err)
    }
  }

  async saveToken(token) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(this.saveUrlValue, {
      method:  "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken || ""
      },
      body: JSON.stringify({
        token:    token,
        platform: "web",
        browser:  navigator.userAgent.slice(0, 200)
      })
    })
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
