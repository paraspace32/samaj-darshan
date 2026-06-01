import { Controller } from "@hotwired/stimulus"

// Shares a biodata image card via WhatsApp.
// 1. Fetches card JPEG from server → shares as image file via Web Share API
// 2. If file sharing fails → opens wa.me with text link as fallback
export default class extends Controller {
  static values = { url: String, name: String, fallback: String }

  async share(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const originalHTML = btn.innerHTML

    btn.disabled = true
    btn.innerHTML = `
      <svg class="animate-spin" width="16" height="16" fill="none" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" opacity="0.3"/>
        <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
      </svg>
      <span>Sharing...</span>
    `

    try {
      // Step 1: Get the card image URL from server
      const resp = await fetch(this.urlValue, { headers: { "Accept": "application/json" } })
      if (!resp.ok) throw new Error(`Server ${resp.status}`)
      const { url: imageUrl } = await resp.json()
      if (!imageUrl) throw new Error("No image URL")

      // Step 2: Fetch the actual image blob
      const imgResp = await fetch(imageUrl)
      if (!imgResp.ok) throw new Error("Image fetch failed")
      const blob = await imgResp.blob()

      // Step 3: Create a File and try sharing it
      const safeName = (this.nameValue || "biodata").replace(/[^a-zA-Z0-9]/g, "_")
      const file = new File([blob], `${safeName}_card.jpg`, { type: "image/jpeg" })

      if (navigator.canShare && navigator.canShare({ files: [file] })) {
        await navigator.share({ files: [file] })
        // Success! Image shared directly
        return
      }

      // canShare not supported or doesn't support files — use wa.me fallback
      this._openFallback()
    } catch (err) {
      if (err.name === "AbortError") return // user cancelled share sheet
      console.warn("Card share failed:", err)
      this._openFallback()
    } finally {
      btn.disabled = false
      btn.innerHTML = originalHTML
    }
  }

  _openFallback() {
    // Open wa.me link with text — guaranteed to work everywhere
    window.location.href = this.fallbackValue
  }
}
