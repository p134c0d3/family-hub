import { Controller } from "@hotwired/stimulus"

/**
 * Dropdown Controller
 *
 * Manages dropdown menus with click-outside-to-close behavior.
 * Also handles mobile navigation menu toggle.
 */
export default class extends Controller {
  static targets = ["button", "menu", "mobileButton", "mobileMenu"]

  connect() {
    // Bind the click outside handler
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener('click', this.boundClickOutside)

    // Close on escape key
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener('click', this.boundClickOutside)
    document.removeEventListener('keydown', this.boundHandleKeydown)
  }

  /**
   * Toggle the dropdown menu visibility
   */
  toggle(event) {
    event.stopPropagation()

    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle('hidden')
    }
  }

  /**
   * Toggle the mobile navigation menu
   */
  toggleMobile(event) {
    event.stopPropagation()

    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.toggle('hidden')
    }
  }

  /**
   * Open the dropdown menu
   */
  open() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove('hidden')
    }
  }

  /**
   * Close the dropdown menu
   */
  close() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }

  /**
   * Handle clicks outside the dropdown
   */
  clickOutside(event) {
    // Check if click is outside the dropdown
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.close()
    }

    // Also close mobile menu if click is outside
    if (this.hasMobileMenuTarget && !this.element.contains(event.target)) {
      this.mobileMenuTarget.classList.add('hidden')
    }
  }

  /**
   * Handle keyboard events
   */
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close()
      if (this.hasMobileMenuTarget) {
        this.mobileMenuTarget.classList.add('hidden')
      }
    }
  }
}
