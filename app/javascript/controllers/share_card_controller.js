import { Controller } from "@hotwired/stimulus"

// Generates and shares a biodata WhatsApp image card.
// On mobile: uses Web Share API for native sharing (WhatsApp, etc.)
// On desktop: falls back to direct download
export default class extends Controller {
  static values = { url: String, name: String }

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
      <span>Generating...</span>
    `

    try {
      // Fetch the card image URL from the server
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Failed to generate card")

      const data = await response.json()
      const imageUrl = data.url

      // Fetch the actual image blob for sharing
      const imageResponse = await fetch(imageUrl)
      const blob = await imageResponse.blob()
      const file = new File([blob], `${this.nameValue || "biodata"}_card.jpg`, { type: "image/jpeg" })

      // Try Web Share API (mobile)
      if (navigator.canShare && navigator.canShare({ files: [file] })) {
        await navigator.share({
          files: [file],
          title: `${this.nameValue} - Biodata`,
          text: `View full biodata on Samaj Darshan`
        })
      } else {
        // Desktop fallback: download the image
        const a = document.createElement("a")
        a.href = URL.createObjectURL(blob)
        a.download = `${this.nameValue || "biodata"}_card.jpg`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(a.href)
      }
    } catch (error) {
      if (error.name !== "AbortError") {
        console.error("Share card error:", error)
        alert("Could not generate card. Please try again.")
      }
    } finally {
      btn.disabled = false
      btn.innerHTML = originalHTML
    }
  }
}
