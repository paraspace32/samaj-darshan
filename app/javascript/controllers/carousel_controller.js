import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "dot", "counter"]
  static values = { index: { type: Number, default: 0 }, autoplay: { type: Boolean, default: true } }

  connect() {
    this.total = this.slideTargets.length
    if (this.total <= 1) return

    // Sync container height to active slide after first image loads
    const firstImg = this.slideTargets[0]?.querySelector("img")
    if (firstImg && !firstImg.complete) {
      firstImg.addEventListener("load", () => this.syncHeight(0), { once: true })
    }

    this.goTo(0)

    if (this.autoplayValue) {
      this.startAutoplay()
      this.element.addEventListener("mouseenter", () => this.stopAutoplay())
      this.element.addEventListener("mouseleave", () => this.startAutoplay())
    }

    this.touchStartX = 0
    this.trackTarget.addEventListener("touchstart", (e) => { this.touchStartX = e.touches[0].clientX }, { passive: true })
    this.trackTarget.addEventListener("touchend", (e) => {
      const diff = this.touchStartX - e.changedTouches[0].clientX
      if (Math.abs(diff) > 50) diff > 0 ? this.next() : this.prev()
    })
  }

  disconnect() {
    this.stopAutoplay()
  }

  prev() {
    this.goTo(this.indexValue <= 0 ? this.total - 1 : this.indexValue - 1)
  }

  next() {
    this.goTo(this.indexValue >= this.total - 1 ? 0 : this.indexValue + 1)
  }

  goToSlide(event) {
    this.goTo(Number(event.currentTarget.dataset.index))
  }

  syncHeight(index) {
    const slide = this.slideTargets[index]
    if (!slide) return
    const wrapper = this.trackTarget.parentElement
    wrapper.style.transition = "height 0.4s ease"
    wrapper.style.height = slide.offsetHeight + "px"
  }

  goTo(index) {
    this.indexValue = index
    this.trackTarget.style.transform = `translateX(-${index * 100}%)`

    this.syncHeight(index)

    // If the target slide's image isn't loaded yet, re-sync once it loads
    const img = this.slideTargets[index]?.querySelector("img")
    if (img && !img.complete) {
      img.addEventListener("load", () => this.syncHeight(index), { once: true })
    }

    this.dotTargets.forEach((dot, i) => {
      dot.classList.toggle("bg-white", i === index)
      dot.classList.toggle("bg-white/40", i !== index)
      dot.classList.toggle("w-6", i === index)
      dot.classList.toggle("w-2", i !== index)
    })

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${index + 1} / ${this.total}`
    }
  }

  startAutoplay() {
    this.stopAutoplay()
    this.timer = setInterval(() => this.next(), 4000)
  }

  stopAutoplay() {
    if (this.timer) { clearInterval(this.timer); this.timer = null }
  }
}
