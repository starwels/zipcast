import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "status"]
  static values = { loadingText: String }

  submit() {
    if (!this.hasSubmitButtonTarget) return

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.dataset.originalText ||= this.submitButtonTarget.value
    this.submitButtonTarget.value = this.loadingTextValue || "Looking up forecast..."
    this.submitButtonTarget.classList.add("submit-button-loading")

    if (this.hasStatusTarget) {
      this.statusTarget.hidden = false
    }
  }
}
