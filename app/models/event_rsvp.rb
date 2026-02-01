# frozen_string_literal: true

# EventRsvp model for Family Hub
#
# Represents a user's RSVP response to an event.
# Each user can only RSVP once per event.
#
# Statuses:
#   - yes: Attending
#   - no: Not attending
#   - maybe: Might attend
#   - tentative: Tentatively attending
#
class EventRsvp < ApplicationRecord
  # RSVP status constants
  STATUSES = %w[yes no maybe tentative].freeze

  # Associations
  belongs_to :event
  belongs_to :user

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :event_id, message: 'has already RSVPed' }

  # Scopes
  scope :attending, -> { where(status: 'yes') }
  scope :not_attending, -> { where(status: 'no') }
  scope :maybe_attending, -> { where(status: %w[maybe tentative]) }

  # Callbacks
  after_create_commit :broadcast_rsvp_update
  after_update_commit :broadcast_rsvp_update

  private

  # Broadcast RSVP update via Turbo Streams
  def broadcast_rsvp_update
    broadcast_replace_to event,
      target: "event_#{event.id}_rsvps",
      partial: 'events/rsvp_list',
      locals: { event: event }
  end
end
