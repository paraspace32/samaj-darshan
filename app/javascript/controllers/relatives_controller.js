import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    const index = Date.now()
    const html = this.templateTarget.innerHTML.replace(/__INDEX__/g, index)
    const div = document.createElement("div")
    div.innerHTML = html
    this.listTarget.appendChild(div.firstElementChild)
  }

  remove(event) {
    const row = event.currentTarget.closest(".relative-row")
    // If row has a destroy flag (existing record), mark it instead of removing DOM
    const destroyFlag = row.querySelector(".destroy-flag")
    if (destroyFlag) {
      destroyFlag.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
