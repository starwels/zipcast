import { Controller } from "@hotwired/stimulus"

const LOADING_TEXT = "Looking up forecast..."
const LOADING_CLASS = "submit-button-loading"

export default class extends Controller {
  static targets = ["submitButton", "status"]
  static values = { loadingText: String }

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
}
