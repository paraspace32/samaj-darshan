import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "imageContainer", "flowerButton"]

  animate(event) {
    // Prevent Turbo form submission — we'll handle it via fetch
    event.preventDefault()
    event.stopPropagation()

    const form = event.target.closest("form")

    // Fire animation immediately
    this.throwFlowersOnImage()

    // Submit the flower via fetch in background (no page reload)
    if (form) {
      const formData = new FormData(form)
      fetch(form.action, {
        method: form.method || "POST",
        body: formData,
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        },
        credentials: "same-origin"
      }).then(() => {
        // After animation settles, reload to show updated state
        setTimeout(() => {
          window.Turbo.visit(window.location.href, { action: "replace" })
        }, 5000)
      })
    }
  }

  throwFlowersOnImage() {
    const canvas = this.canvasTarget
    const emojis = ["🌸", "🌺", "🌷", "🌹", "💐", "🌻", "🪷", "🌼"]
    const count = 45

    for (let i = 0; i < count; i++) {
      const flower = document.createElement("div")
      const emoji = emojis[Math.floor(Math.random() * emojis.length)]
      const size = 18 + Math.random() * 24
      const delay = Math.random() * 1.5 // stagger over 1.5s

      // Start from bottom center
      const startX = 35 + Math.random() * 30
      const startY = 85 + Math.random() * 15

      // Land at random position across the image
      const endX = 5 + Math.random() * 90
      const endY = 5 + Math.random() * 75

      // Arc height
      const arcHeight = 35 + Math.random() * 45

      flower.textContent = emoji
      flower.style.cssText = `
        position: absolute;
        left: ${startX}%;
        top: ${startY}%;
        font-size: ${size}px;
        pointer-events: none;
        z-index: 15;
        opacity: 0;
        transform: scale(0.3);
        transition: none;
      `
      canvas.appendChild(flower)

      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          // Phase 1: burst upward (slow arc ~1s)
          const midX = (startX + endX) / 2 + (Math.random() - 0.5) * 20
          const midY = Math.min(startY, endY) - arcHeight

          flower.style.transition = `all ${0.8 + Math.random() * 0.5}s cubic-bezier(0.2, 0.8, 0.3, 1)`
          flower.style.transitionDelay = `${delay}s`
          flower.style.left = `${midX}%`
          flower.style.top = `${midY}%`
          flower.style.opacity = "1"
          flower.style.transform = `scale(1.3) rotate(${(Math.random() - 0.5) * 200}deg)`

          // Phase 2: float down to resting position (~1s)
          const fallDelay = (delay + 0.8 + Math.random() * 0.5) * 1000
          setTimeout(() => {
            flower.style.transition = `all ${0.8 + Math.random() * 0.6}s cubic-bezier(0.4, 0, 0.6, 1)`
            flower.style.transitionDelay = "0s"
            flower.style.left = `${endX}%`
            flower.style.top = `${endY}%`
            flower.style.transform = `scale(1) rotate(${Math.random() * 360}deg)`
            flower.style.opacity = "0.95"
          }, fallDelay)

          // Phase 3: rest on image for a while, then fade out slowly
          const restDuration = 2500 + Math.random() * 1500
          setTimeout(() => {
            flower.style.transition = "opacity 2s ease-out"
            flower.style.opacity = "0"
          }, fallDelay + restDuration)

          // Cleanup
          setTimeout(() => {
            flower.remove()
          }, fallDelay + restDuration + 2500)
        })
      })
    }
  }
}
