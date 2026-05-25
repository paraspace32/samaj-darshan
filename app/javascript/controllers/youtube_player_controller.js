import { Controller } from "@hotwired/stimulus"

// Replaces YouTube thumbnail with embedded iframe on click
// Prevents mobile redirect to YouTube app
export default class extends Controller {
  static targets = ["thumb", "playBtn", "player"]
  static values = { videoId: String }

  play() {
    const iframe = document.createElement("iframe")
    iframe.src = `https://www.youtube.com/embed/${this.videoIdValue}?autoplay=1&rel=0&playsinline=1`
    iframe.className = "absolute inset-0 w-full h-full"
    iframe.frameBorder = "0"
    iframe.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    iframe.allowFullscreen = true

    this.thumbTarget.classList.add("hidden")
    this.playBtnTarget.classList.add("hidden")
    this.playerTarget.classList.remove("hidden")
    this.playerTarget.appendChild(iframe)
  }
}
