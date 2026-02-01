import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["presetSelect", "customInput", "customField"]

  connect() {
    this.toggleCustomField()
  }

  toggleCustomField() {
    const isCustom = this.presetSelectTarget.value === 'custom'
    this.customFieldTarget.classList.toggle('hidden', !isCustom)
    this.customInputTarget.required = isCustom
  }

  presetChanged() {
    this.toggleCustomField()
  }
}
