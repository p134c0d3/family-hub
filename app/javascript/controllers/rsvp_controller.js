import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "noteField"]
  static values = { eventId: Number, currentStatus: String }

  respond(event) {
    const status = event.currentTarget.dataset.status

    // Optimistic UI update
    this.buttonTargets.forEach(btn => {
      btn.classList.remove('active', 'bg-theme-primary', 'text-white')
      btn.classList.add('bg-theme-surface')
    })
    event.currentTarget.classList.add('active', 'bg-theme-primary', 'text-white')
    event.currentTarget.classList.remove('bg-theme-surface')

    // Submit RSVP
    fetch(`/events/${this.eventIdValue}/rsvps`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: JSON.stringify({ status: status })
    })
  }

  toggleNote() {
    this.noteFieldTarget.classList.toggle('hidden')
  }
}
