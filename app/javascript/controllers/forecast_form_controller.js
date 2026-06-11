import { Controller } from "@hotwired/stimulus"

const LOADING_TEXT = "Looking up forecast..."
const LOADING_CLASS = "submit-button-loading"

export default class extends Controller {
  static targets = ["submitButton", "status"]
  static values = { loadingText: String }

  connect() {
    this.reset = this.reset.bind(this)
    document.addEventListener("turbo:before-cache", this.reset)
    document.addEventListener("turbo:render", this.reset)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.reset)
    document.removeEventListener("turbo:render", this.reset)
  }

  submit() {
    if (!this.hasSubmitButtonTarget) return

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.dataset.originalText ||= this.submitButtonTarget.value
    this.submitButtonTarget.value = this.loadingTextValue || LOADING_TEXT
    this.submitButtonTarget.classList.add(LOADING_CLASS)

    if (this.hasStatusTarget) {
      this.statusTarget.hidden = false
    }
  }

  reset() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.value = this.submitButtonTarget.dataset.originalText || this.submitButtonTarget.value
      this.submitButtonTarget.classList.remove(LOADING_CLASS)
    }

    if (this.hasStatusTarget) {
      this.statusTarget.hidden = true
    }
  }
}
