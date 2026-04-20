import { Controller } from "@hotwired/stimulus"

const SIZES = { normal: 1, large: 1.18, xl: 1.35 }
const BASE_REM = 1.05
const STORAGE_KEY = "article-font-size"

export default class extends Controller {
  static targets = ["prose", "btn"]
  static values = { size: { type: String, default: "normal" } }

  connect() {
    const saved = localStorage.getItem(STORAGE_KEY) || "normal"
    this.apply(saved)
  }

  set(event) {
    this.apply(event.currentTarget.dataset.size)
  }

  apply(size) {
    if (!SIZES[size]) size = "normal"
    this.sizeValue = size

    const rem = (BASE_REM * SIZES[size]).toFixed(3)
    if (this.hasProseTarget) {
      this.proseTarget.style.fontSize = rem + "rem"
    }

    this.btnTargets.forEach(btn => {
      const active = btn.dataset.size === size
      btn.classList.toggle("text-orange-600", active)
      btn.classList.toggle("bg-orange-50", active)
      btn.classList.toggle("border-orange-200", active)
      btn.classList.toggle("font-black", active)
      btn.classList.toggle("text-stone-400", !active)
      btn.classList.toggle("border-stone-200", !active)
    })

    localStorage.setItem(STORAGE_KEY, size)
  }
}
