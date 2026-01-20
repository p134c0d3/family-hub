import { Controller } from "@hotwired/stimulus"

/**
 * Flash Controller
 *
 * Handles flash message display and auto-dismissal.
 * Messages automatically fade out after 5 seconds.
 */
export default class extends Controller {
  static targets = ["message"]

  connect() {
    // Auto-dismiss messages after 5 seconds
    this.messageTargets.forEach((message, index) => {
      setTimeout(() => {
        this.dismissMessage(message)
      }, 5000 + (index * 500)) // Stagger dismissals
    })
  }

  /**
   * Dismiss a flash message (triggered by close button)
   */
  dismiss(event) {
    const message = event.target.closest('[data-flash-target="message"]')
    if (message) {
      this.dismissMessage(message)
    }
  }

  /**
   * Animate and remove a message element
   */
  dismissMessage(message) {
    // Add exit animation
    message.classList.remove('animate-slide-in')
    message.classList.add('animate-slide-out')

    // Remove after animation completes
    setTimeout(() => {
      message.remove()
    }, 300)
  }
}
