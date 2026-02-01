import { Controller } from "@hotwired/stimulus"
import Coloris from 'coloris'

export default class extends Controller {
  static targets = ["colorInput", "preview", "hexInput"]
  static values = { colors: Object }

  connect() {
    this.initializeColorPickers()
  }

  initializeColorPickers() {
    Coloris.init()

    this.colorInputTargets.forEach(input => {
      Coloris({
        el: input,
        theme: 'polaroid',
        swatches: [
          '#3b82f6', '#8b5cf6', '#f59e0b', '#10b981',
          '#ef4444', '#ec4899', '#6366f1', '#14b8a6'
        ],
        alpha: false,
        formatToggle: false,
        closeButton: true
      })

      input.addEventListener('change', (e) => this.updateColor(e))
    })
  }

  updateColor(event) {
    const input = event.target
    const colorKey = input.dataset.colorKey
    const value = input.value

    // Update hex input if exists
    const hexInput = this.element.querySelector(`[data-hex-for="${colorKey}"]`)
    if (hexInput) hexInput.value = value

    // Update preview
    this.updatePreview(colorKey, value)
  }

  updateFromHex(event) {
    const input = event.target
    const colorKey = input.dataset.hexFor
    let value = input.value

    // Add # if missing
    if (!value.startsWith('#')) value = '#' + value

    // Validate hex
    if (/^#[0-9a-fA-F]{6}$/.test(value)) {
      const colorInput = this.element.querySelector(`[data-color-key="${colorKey}"]`)
      if (colorInput) {
        colorInput.value = value
        Coloris.setColor(value, colorInput)
      }
      this.updatePreview(colorKey, value)
    }
  }

  updatePreview(colorKey, value) {
    // Update CSS variable for live preview
    document.documentElement.style.setProperty(`--color-${colorKey.replace(/_/g, '-')}`, value)

    // Update preview swatch
    const swatch = this.element.querySelector(`[data-preview-for="${colorKey}"]`)
    if (swatch) swatch.style.backgroundColor = value
  }

  resetPreview() {
    // Reload page to reset CSS variables
    window.location.reload()
  }
}
