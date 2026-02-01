# frozen_string_literal: true

# EventRsvpsController handles RSVP responses to calendar events
#
# Users can RSVP with status: yes, no, maybe, tentative
# RSVPs are unique per user per event (find_or_initialize_by)
#
class EventRsvpsController < ApplicationController
  before_action :require_authentication
  before_action :set_event

  # POST /events/:event_id/rsvps
  def create
    @rsvp = @event.event_rsvps.find_or_initialize_by(user: current_user)
    @rsvp.status = params[:status]
    @rsvp.note = params[:note]

    respond_to do |format|
      if @rsvp.save
        format.turbo_stream
        format.html { redirect_to @event, notice: "RSVP updated." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("event_#{@event.id}_rsvp_form", partial: "events/rsvp_form", locals: { event: @event, errors: @rsvp.errors.full_messages }), status: :unprocessable_entity }
        format.html { redirect_to @event, alert: @rsvp.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
