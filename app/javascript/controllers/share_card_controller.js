import { Controller } from "@hotwired/stimulus"

// Generates and shares a biodata WhatsApp image card.
// Strategy:
// 1. Fetch card image URL from server (JSON endpoint)
// 2. Fetch the image as a blob and share as a File via Web Share API
// 3. If file sharing unsupported, fall back to URL-only share
// 4. If no share API at all (desktop), navigate to download URL
export default class extends Controller {
  static values = { url: String, downloadUrl: String, name: String }

  async share(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const originalHTML = btn.innerHTML

    // Show loading state
    btn.disabled = true
    btn.innerHTML = `
      <svg class="animate-spin" width="16" height="16" fill="none" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" opacity="0.3"/>
        <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
      </svg>
      <span>Loading...</span>
    `

    const downloadUrl = this.hasDownloadUrlValue ? this.downloadUrlValue : null
    const cardJsonUrl = this.urlValue

    try {
      // Step 1: Get card image URL from server
      const response = await fetch(cardJsonUrl, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) throw new Error(`Server returned ${response.status}`)

      const data = await response.json()
      const imageUrl = data.url
      if (!imageUrl) throw new Error("No image URL in response")

      // Step 2: Try sharing the image as a file (best experience for WhatsApp)
      if (navigator.canShare) {
        try {
          const imageResponse = await fetch(imageUrl)
          if (!imageResponse.ok) throw new Error("Image fetch failed")

          const blob = await imageResponse.blob()
          const fileName = `${(this.nameValue || "biodata").replace(/[^a-zA-Z0-9]/g, "_")}_card.jpg`
          const file = new File([blob], fileName, { type: "image/jpeg" })

          if (navigator.canShare({ files: [file] })) {
            await navigator.share({
              files: [file],
              title: `${this.nameValue || "Biodata"} - Samaj Darshan`
            })
            return // Success — done
          }
        } catch (shareErr) {
          if (shareErr.name === "AbortError") return // User cancelled — that's fine
          console.warn("File share failed, trying URL share:", shareErr)
        }
      }

      // Step 3: Fallback — share URL only (shows as a link, not image)
      if (navigator.share) {
        try {
          await navigator.share({
            title: `${this.nameValue || "Biodata"} - Samaj Darshan`,
            text: `${this.nameValue || "Biodata"} — View full biodata on Samaj Darshan`,
            url: downloadUrl || imageUrl
          })
          return
        } catch (urlShareErr) {
          if (urlShareErr.name === "AbortError") return
          console.warn("URL share also failed:", urlShareErr)
        }
      }

      // Step 4: Final fallback — navigate to the image directly
      window.location.href = downloadUrl || imageUrl
    } catch (error) {
      console.error("Share card error:", error)
      // Last resort: try to open the download URL if we have it
      if (downloadUrl) {
        window.location.href = downloadUrl
      } else {
        alert("Could not generate card. Please try again.")
      }
    } finally {
      btn.disabled = false
      btn.innerHTML = originalHTML
    }
  }
}
