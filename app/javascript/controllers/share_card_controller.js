import { Controller } from "@hotwired/stimulus"

// Generates and shares a biodata WhatsApp image card.
// Strategy:
// 1. Open download_card URL directly (synchronous, no popup-blocker issues)
// 2. After page loads the card, try Web Share API with the direct URL
// 3. Fallback: navigate to the card image for manual save/share
export default class extends Controller {
  static values = { url: String, downloadUrl: String, name: String }

  share(event) {
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

    // Use the download_card URL which does a server-side redirect to the blob.
    // This avoids all fetch→blob→File→share complexity that breaks on Safari.
    const downloadUrl = this.hasDownloadUrlValue ? this.downloadUrlValue : null
    const cardUrl = this.urlValue

    // Try Web Share API with URL only (no file fetching) — works reliably on iOS Safari
    if (navigator.share) {
      const shareData = {
        title: `${this.nameValue || "Biodata"} - Samaj Darshan`,
        text: `${this.nameValue || "Biodata"} — View full biodata on Samaj Darshan`,
        url: downloadUrl || cardUrl
      }

      navigator.share(shareData)
        .catch((err) => {
          // User cancelled — that's fine
          if (err.name !== "AbortError") {
            console.warn("Share failed, opening card directly:", err)
            // Fallback: just open the card
            window.location.href = downloadUrl || cardUrl
          }
        })
        .finally(() => {
          btn.disabled = false
          btn.innerHTML = originalHTML
        })
    } else {
      // Desktop or no share API: navigate directly to download the card
      window.location.href = downloadUrl || cardUrl
      // Restore button after a short delay (page may navigate away)
      setTimeout(() => {
        btn.disabled = false
        btn.innerHTML = originalHTML
      }, 2000)
    }
  }
}
