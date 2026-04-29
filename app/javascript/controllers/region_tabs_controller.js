import { Controller } from "@hotwired/stimulus"

// Handles region tab active-state highlighting when tabs are clicked.
// Turbo Frame takes care of loading the news content; this controller
// only updates the visual active class immediately on click.
//
// Usage:
//   data-controller="region-tabs"  on the tab strip wrapper
//   data-region-tabs-target="tab"  on each tab link
//   data-action="region-tabs#select" on each tab link
export default class extends Controller {
  static targets = ["tab"]

  select(event) {
    this.tabTargets.forEach(t => {
      t.classList.remove("region-tab-active")
    })
    event.currentTarget.classList.add("region-tab-active")
  }
}
