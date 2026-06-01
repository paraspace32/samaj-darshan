import { Controller } from "@hotwired/stimulus"

// Generates and shares a biodata WhatsApp image card.
// On mobile: uses Web Share API for native sharing (WhatsApp, etc.)
// On desktop: opens image in new tab for save/share
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
      // Step 1: Get card image URL from server
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error(`Server returned ${response.status}`)

      const data = await response.json()
      const imageUrl = data.url

      if (!imageUrl) throw new Error("No image URL in response")

      // Step 2: Try native share on mobile (with file)
      let shared = false
      if (navigator.canShare) {
        try {
          const imageResponse = await fetch(imageUrl)
          if (imageResponse.ok) {
            const blob = await imageResponse.blob()
            const fileName = `${(this.nameValue || "biodata").replace(/[^a-zA-Z0-9]/g, "_")}_card.jpg`
            const file = new File([blob], fileName, { type: "image/jpeg" })

            if (navigator.canShare({ files: [file] })) {
              await navigator.share({
                files: [file],
                title: `${this.nameValue} - Biodata`,
                text: "View full biodata on Samaj Darshan"
              })
              shared = true
            }
          }
        } catch (e) {
          if (e.name === "AbortError") { shared = true } // User cancelled — still counts
          else { console.warn("Native share failed, falling back:", e) }
        }
      }

      // Step 3: Fallback — open image in new tab (works everywhere)
      if (!shared) {
        window.open(imageUrl, "_blank")
      }
    } catch (error) {
      console.error("Share card error:", error)
      alert("Could not generate card. Please try again.")
    } finally {
      btn.disabled = false
      btn.innerHTML = originalHTML
    }
  }
}
