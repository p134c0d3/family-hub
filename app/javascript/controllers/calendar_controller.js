import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar", "dateDisplay", "viewToggle"]
  static values = {
    date: String,
    view: { type: String, default: "month" }
  }

  connect() {
    this.updateDateDisplay()
  }

  navigate(event) {
    const direction = event.currentTarget.dataset.direction
    this.navigateToDate(direction)
  }

  navigateToDate(direction) {
    const currentDate = new Date(this.dateValue)

    switch (this.viewValue) {
      case 'month':
        currentDate.setMonth(currentDate.getMonth() + (direction === 'next' ? 1 : -1))
        break
      case 'week':
        currentDate.setDate(currentDate.getDate() + (direction === 'next' ? 7 : -7))
        break
      case 'day':
        currentDate.setDate(currentDate.getDate() + (direction === 'next' ? 1 : -1))
        break
    }

    this.dateValue = currentDate.toISOString().split('T')[0]
    this.loadCalendar()
  }

  changeView(event) {
    this.viewValue = event.currentTarget.dataset.view
    this.loadCalendar()
  }

  today() {
    this.dateValue = new Date().toISOString().split('T')[0]
    this.loadCalendar()
  }

  loadCalendar() {
    const url = `/calendar?date=${this.dateValue}&view=${this.viewValue}`
    Turbo.visit(url, { frame: "calendar-frame" })
  }

  updateDateDisplay() {
    if (!this.hasDateDisplayTarget) return

    const date = new Date(this.dateValue)
    const options = this.viewValue === 'day'
      ? { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
      : { year: 'numeric', month: 'long' }

    this.dateDisplayTarget.textContent = date.toLocaleDateString('en-US', options)
  }

  dateValueChanged() {
    this.updateDateDisplay()
  }

  openEventModal(event) {
    const startAt = event.currentTarget.dataset.startAt
    const url = `/events/new?start_at=${startAt}`

    // Open modal via Turbo Frame
    Turbo.visit(url, { frame: "modal" })
  }
}
