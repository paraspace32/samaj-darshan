import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas"]

  animate(event) {
    this.spawnFlowers()
  }

  spawnFlowers() {
    const canvas = this.canvasTarget
    const emojis = ["🌸", "🌺", "🌷", "🌹", "💐", "🌻", "🪷", "🌼"]
    const count = 35

    for (let i = 0; i < count; i++) {
      const flower = document.createElement("div")
      const emoji = emojis[Math.floor(Math.random() * emojis.length)]
      const left = Math.random() * 100
      const size = 20 + Math.random() * 28
      const duration = 2 + Math.random() * 3
      const delay = Math.random() * 1.5
      const sway = (Math.random() - 0.5) * 200

      flower.textContent = emoji
      flower.style.position = "fixed"
      flower.style.top = "-60px"
      flower.style.left = `${left}vw`
      flower.style.fontSize = `${size}px`
      flower.style.pointerEvents = "none"
      flower.style.zIndex = "9999"
      flower.style.opacity = "0"
      flower.style.transition = "none"

      canvas.appendChild(flower)

      // Trigger animation via requestAnimationFrame for smooth start
      requestAnimationFrame(() => {
        flower.style.transition = `all ${duration}s ease-in`
        flower.style.transitionDelay = `${delay}s`
        flower.style.transform = `translateY(${window.innerHeight + 100}px) translateX(${sway}px) rotate(${360 + Math.random() * 360}deg)`
        flower.style.opacity = "1"

        // Fade out near end
        setTimeout(() => {
          flower.style.opacity = "0"
        }, (delay + duration * 0.7) * 1000)

        // Cleanup
        setTimeout(() => {
          flower.remove()
        }, (delay + duration + 0.5) * 1000)
      })
    }
  }
}
