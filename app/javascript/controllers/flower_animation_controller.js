import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "imageContainer"]

  animate(event) {
    this.throwFlowersOnImage()
  }

  throwFlowersOnImage() {
    const canvas = this.canvasTarget
    const container = this.imageContainerTarget
    const rect = container.getBoundingClientRect()
    const emojis = ["🌸", "🌺", "🌷", "🌹", "💐", "🌻", "🪷", "🌼"]
    const count = 40

    for (let i = 0; i < count; i++) {
      const flower = document.createElement("div")
      const emoji = emojis[Math.floor(Math.random() * emojis.length)]
      const size = 18 + Math.random() * 22
      const delay = Math.random() * 0.8

      // Start from bottom center of the image (where the button is)
      const startX = 40 + Math.random() * 20 // 40-60% horizontal
      const startY = 90 + Math.random() * 10 // near bottom

      // Land at random position across the image
      const endX = 5 + Math.random() * 90
      const endY = 5 + Math.random() * 70

      // Arc height — flowers burst upward then fall
      const arcHeight = 30 + Math.random() * 40

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

      // Phase 1: burst upward
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          // Arc midpoint
          const midX = (startX + endX) / 2 + (Math.random() - 0.5) * 20
          const midY = Math.min(startY, endY) - arcHeight

          flower.style.transition = `all ${0.4 + Math.random() * 0.3}s cubic-bezier(0.2, 0.8, 0.3, 1)`
          flower.style.transitionDelay = `${delay}s`
          flower.style.left = `${midX}%`
          flower.style.top = `${midY}%`
          flower.style.opacity = "1"
          flower.style.transform = `scale(1.2) rotate(${(Math.random() - 0.5) * 180}deg)`

          // Phase 2: fall to resting position
          const fallDelay = (delay + 0.4 + Math.random() * 0.3) * 1000
          setTimeout(() => {
            flower.style.transition = `all ${0.5 + Math.random() * 0.4}s cubic-bezier(0.4, 0, 0.6, 1)`
            flower.style.transitionDelay = "0s"
            flower.style.left = `${endX}%`
            flower.style.top = `${endY}%`
            flower.style.transform = `scale(1) rotate(${Math.random() * 360}deg)`
            flower.style.opacity = "0.9"
          }, fallDelay)

          // Phase 3: fade out gently
          setTimeout(() => {
            flower.style.transition = "opacity 1.5s ease-out"
            flower.style.opacity = "0"
          }, fallDelay + 2000)

          // Cleanup
          setTimeout(() => {
            flower.remove()
          }, fallDelay + 4000)
        })
      })
    }
  }
}
