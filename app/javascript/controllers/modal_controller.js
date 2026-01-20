import { Controller } from "@hotwired/stimulus"

/**
 * Modal Controller
 *
 * Handles modal dialogs with backdrop, animations, and keyboard navigation.
 *
 * Usage:
 *   <div data-controller="modal" data-modal-open-class="opacity-100" data-modal-closed-class="opacity-0">
 *     <button data-action="click->modal#open">Open Modal</button>
 *     <div data-modal-target="container" class="hidden">
 *       <div data-modal-target="backdrop" data-action="click->modal#close"></div>
 *       <div data-modal-target="dialog">
 *         <button data-action="click->modal#close">Close</button>
 *       </div>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["container", "backdrop", "dialog"]
  static classes = ["open", "closed"]
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    // Close on escape key
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)

    // Listen for custom open event (for triggering from outside the controller scope)
    this.boundOpen = this.open.bind(this)
    this.element.addEventListener("modal:open", this.boundOpen)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    this.element.removeEventListener("modal:open", this.boundOpen)
    this.enableScroll()
  }

  open(event) {
    if (event) event.preventDefault()

    this.openValue = true
    this.containerTarget.classList.remove("hidden")

    // Disable body scroll
    this.disableScroll()

    // Animate in
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.backdropTarget.classList.add("opacity-100")
      this.dialogTarget.classList.remove("opacity-0", "scale-95")
      this.dialogTarget.classList.add("opacity-100", "scale-100")
    })

    // Focus first focusable element
    requestAnimationFrame(() => {
      const focusable = this.dialogTarget.querySelector(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      )
      if (focusable) focusable.focus()
    })
  }

  close(event) {
    if (event) event.preventDefault()

    this.openValue = false

    // Animate out
    this.backdropTarget.classList.remove("opacity-100")
    this.backdropTarget.classList.add("opacity-0")
    this.dialogTarget.classList.remove("opacity-100", "scale-100")
    this.dialogTarget.classList.add("opacity-0", "scale-95")

    // Hide after animation
    setTimeout(() => {
      this.containerTarget.classList.add("hidden")
      this.enableScroll()
    }, 200)
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.openValue) {
      this.close()
    }
  }

  disableScroll() {
    document.body.style.overflow = "hidden"
  }

  enableScroll() {
    document.body.style.overflow = ""
  }

  // Method to be called when confirm action is triggered
  confirm(event) {
    // Find the form or link to submit
    const form = this.element.querySelector("form[data-modal-form]")
    if (form) {
      form.requestSubmit()
    }
    this.close()
  }
}
