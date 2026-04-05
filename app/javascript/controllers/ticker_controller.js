import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track"]

  connect() {
    this.paused = false
    this.speed = 0.5
    this.mobile = window.matchMedia("(max-width: 639px)").matches

    if (!this.mobile) {
      this.start()
    }
  }

  disconnect() {
    this.stop()
  }

  start() {
    this.frame = requestAnimationFrame(() => this.tick())
  }

  stop() {
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  tick() {
    if (!this.paused) {
      const track = this.trackTarget
      track.scrollLeft += this.speed
      if (track.scrollLeft >= track.scrollWidth - track.clientWidth) {
        track.scrollLeft = 0
      }
    }
    this.frame = requestAnimationFrame(() => this.tick())
  }

  pause() { this.paused = true }
  resume() { this.paused = false }
}
