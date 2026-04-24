import { Controller } from "@hotwired/stimulus"

// Lightweight tab switcher used in trending / latest sections.
// Usage:
//   data-controller="tab-switcher"
//   data-tab-switcher-target="tab"   on each tab button
//   data-tab-switcher-target="panel" on each content panel (order matches tabs)
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Ensure first tab is visually active on connect
    this._activate(0)
  }

  switch(event) {
    const idx = this.tabTargets.indexOf(event.currentTarget)
    if (idx !== -1) this._activate(idx)
  }

  _activate(activeIdx) {
    this.tabTargets.forEach((tab, i) => {
      const on = i === activeIdx
      tab.classList.toggle("border-orange-500", on)
      tab.classList.toggle("text-orange-600",   on)
      tab.classList.toggle("font-black",         on)
      tab.classList.toggle("border-transparent", !on)
      tab.classList.toggle("text-gray-500",      !on)
      tab.classList.toggle("font-bold",          !on)
    })
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== activeIdx)
    })
  }
}
