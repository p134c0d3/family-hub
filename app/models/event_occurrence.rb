# frozen_string_literal: true

# EventOccurrence value object for Family Hub
#
# Represents a single occurrence of a recurring event.
# This is not a database-backed model, but a value object that wraps
# an Event and a specific occurrence time from the ice_cube schedule.
#
class EventOccurrence
  attr_reader :event, :start_at

  # Delegate common attributes to the parent event
  delegate :id, :title, :description, :color, :visibility, :created_by,
           :all_day, :event_rsvps, :rsvp_users, to: :event

  def initialize(event, occurrence_time)
    @event = event
    @start_at = occurrence_time
  end

  # Calculate end_at based on the original event's duration
  def end_at
    return nil unless event.end_at
    duration = event.end_at - event.start_at
    start_at + duration
  end

  # Aliases for simple_calendar compatibility
  def start_time
    start_at
  end

  def end_time
    end_at
  end

  # This is always a recurring event occurrence
  def recurring?
    true
  end

  # Mark this as an occurrence (not the base event)
  def occurrence?
    true
  end
end
