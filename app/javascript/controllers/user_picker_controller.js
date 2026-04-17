import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "dropdown", "empty"]
  static values  = { url: String }

  connect() {
    this._timer  = null
    this._active = -1
    // Close on outside click
    this._outside = (e) => { if (!this.element.contains(e.target)) this.close() }
    document.addEventListener("click", this._outside)
  }

  disconnect() {
    document.removeEventListener("click", this._outside)
    clearTimeout(this._timer)
  }

  // Called on input event — debounce 200 ms
  search() {
    clearTimeout(this._timer)
    this._active = -1
    const q = this.inputTarget.value.trim()
    this._timer = setTimeout(() => this._fetch(q), 200)
  }

  // Keyboard navigation
  keydown(e) {
    const items = this.dropdownTarget.querySelectorAll("[data-item]")
    if (!items.length) return
    if (e.key === "ArrowDown") {
      e.preventDefault()
      this._active = Math.min(this._active + 1, items.length - 1)
      this._highlight(items)
    } else if (e.key === "ArrowUp") {
      e.preventDefault()
      this._active = Math.max(this._active - 1, 0)
      this._highlight(items)
    } else if (e.key === "Enter" && this._active >= 0) {
      e.preventDefault()
      items[this._active].click()
    } else if (e.key === "Escape") {
      this.close()
    }
  }

  select(e) {
    const { id, label } = e.currentTarget.dataset
    this.hiddenTarget.value  = id
    this.inputTarget.value   = label
    this.inputTarget.classList.remove("border-gray-200", "border-red-400")
    this.inputTarget.classList.add("border-orange-400")
    this.close()
  }

  clear() {
    this.hiddenTarget.value = ""
    this.inputTarget.value  = ""
    this.inputTarget.focus()
    this._fetch("")
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    this._active = -1
  }

  async _fetch(q) {
    const url = `${this.urlValue}?q=${encodeURIComponent(q)}`
    try {
      const res   = await fetch(url, { headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" } })
      const users = await res.json()
      this._render(users)
    } catch (_) { /* network error — ignore */ }
  }

  _render(users) {
    const dd = this.dropdownTarget
    dd.innerHTML = ""
    if (!users.length) {
      dd.innerHTML = `<div class="px-4 py-3 text-sm text-gray-400 text-center">No users found</div>`
    } else {
      users.forEach((u, i) => {
        const btn = document.createElement("button")
        btn.type = "button"
        btn.setAttribute("data-item", "")
        btn.setAttribute("data-id",    u.id)
        btn.setAttribute("data-label", u.label)
        btn.setAttribute("data-action", "click->user-picker#select")
        btn.className = "w-full text-left px-4 py-2.5 text-sm hover:bg-orange-50 transition-colors flex items-center gap-2 cursor-pointer"
        // Split at · to bold the name part
        const parts = u.label.split(" · ")
        btn.innerHTML = `<span class="font-semibold text-gray-900 truncate">${parts[0]}</span><span class="text-gray-400 text-xs ml-auto shrink-0">${parts[1] || ""}</span>`
        dd.appendChild(btn)
      })
    }
    dd.classList.remove("hidden")
    this._active = -1
  }

  _highlight(items) {
    items.forEach((el, i) => {
      el.classList.toggle("bg-orange-50", i === this._active)
    })
    if (this._active >= 0) items[this._active].scrollIntoView({ block: "nearest" })
  }
}
