import { Controller } from "@hotwired/stimulus"

// Emoji picker controller for message reactions
//
// Shows a popup with common emojis when clicking the reaction button.
// Clicking an emoji submits a form to toggle the reaction.
//
export default class extends Controller {
  static targets = ["picker", "button"]
  static values = {
    messageId: Number,
    chatId: Number
  }

  // Common emoji reactions
  static emojis = ["👍", "❤️", "😂", "😮", "😢", "😡", "🎉", "🤔"]

  connect() {
    // Close picker when clicking outside
    this.outsideClickHandler = (event) => {
      if (!this.element.contains(event.target)) {
        this.close()
      }
    }
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.hasPickerTarget) {
      this.pickerTarget.classList.toggle("hidden")
    }
  }

  close() {
    if (this.hasPickerTarget) {
      this.pickerTarget.classList.add("hidden")
    }
  }

  // Called when an emoji is selected
  select(event) {
    // Form submission is handled by Turbo
    this.close()
  }
}
