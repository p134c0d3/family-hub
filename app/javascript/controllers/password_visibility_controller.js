import { Controller } from "@hotwired/stimulus"

// Password visibility toggle controller
//
// Toggles password field between masked (dots) and visible (text).
// Also supports copying the password value to clipboard.
//
export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"]

  connect() {
    // Ensure icons are in correct initial state
    this.updateIcons()
  }

  toggle() {
    if (this.hasInputTarget) {
      const isPassword = this.inputTarget.type === "password"
      this.inputTarget.type = isPassword ? "text" : "password"
      this.updateIcons()
    }
  }

  updateIcons() {
    if (!this.hasInputTarget) return

    const isPassword = this.inputTarget.type === "password"

    if (this.hasShowIconTarget && this.hasHideIconTarget) {
      // Show the "eye" icon when password is hidden (to reveal)
      // Show the "eye-off" icon when password is visible (to hide)
      this.showIconTarget.classList.toggle("hidden", !isPassword)
      this.hideIconTarget.classList.toggle("hidden", isPassword)
    }
  }

  // Copy password to clipboard
  async copy() {
    if (this.hasInputTarget && this.inputTarget.value) {
      try {
        await navigator.clipboard.writeText(this.inputTarget.value)

        // Show brief feedback
        const button = this.element.querySelector('[data-action*="copy"]')
        if (button) {
          const originalHTML = button.innerHTML
          button.innerHTML = `
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          `
          setTimeout(() => {
            button.innerHTML = originalHTML
          }, 1500)
        }
      } catch (err) {
        console.error('Failed to copy password:', err)
      }
    }
  }
}
