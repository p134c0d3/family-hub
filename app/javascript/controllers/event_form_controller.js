import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recurrenceFields", "recurrenceToggle", "endDate", "allDay"]
  static values = { recurring: Boolean }

  connect() {
    this.toggleRecurrenceFields()
  }

  toggleAllDay(event) {
    const timeInputs = this.element.querySelectorAll('input[type="time"]')
    timeInputs.forEach(input => {
      input.disabled = event.target.checked
      input.closest('.form-group')?.classList.toggle('opacity-50', event.target.checked)
    })
  }

  toggleRecurrence(event) {
    this.recurringValue = event.target.checked
    this.toggleRecurrenceFields()
  }

  toggleRecurrenceFields() {
    if (this.hasRecurrenceFieldsTarget) {
      this.recurrenceFieldsTarget.classList.toggle('hidden', !this.recurringValue)
    }
  }

  setColor(event) {
    const color = event.currentTarget.dataset.color
    this.element.querySelector('input[name="event[color]"]').value = color

    // Update preview
    const preview = this.element.querySelector('.color-preview')
    if (preview) preview.style.backgroundColor = color
  }
}
