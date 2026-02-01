# frozen_string_literal: true

# EventRemindersController handles event reminder creation and deletion
#
# Reminders can be created with preset minutes (15, 60, 1440, 10080)
# or custom minutes_before values.
#
class EventRemindersController < ApplicationController
  before_action :require_authentication
  before_action :set_event

  # POST /events/:event_id/reminders
  def create
    minutes = if params[:custom_minutes].present?
      params[:custom_minutes].to_i
    else
      params[:minutes_before].to_i
    end

    @reminder = @event.event_reminders.build(
      user: current_user,
      minutes_before: minutes
    )

    respond_to do |format|
      if @reminder.save
        format.turbo_stream
        format.html { redirect_to @event, notice: "Reminder set." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace("event_#{@event.id}_reminder_form", partial: "events/reminder_form", locals: { event: @event, errors: @reminder.errors.full_messages }), status: :unprocessable_entity }
        format.html { redirect_to @event, alert: @reminder.errors.full_messages.join(", ") }
      end
    end
  end

  # DELETE /events/:event_id/reminders/:id
  def destroy
    @reminder = current_user.event_reminders.find(params[:id])
    @reminder.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@reminder) }
      format.html { redirect_to @event, notice: "Reminder removed." }
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
