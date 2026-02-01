# frozen_string_literal: true

# EventsController handles calendar events
#
# Events support:
#   - Full CRUD operations
#   - Recurring events via ice_cube
#   - Public/private visibility
#   - Date/view filtering
#   - Turbo Stream responses for modals
#
class EventsController < ApplicationController
  before_action :require_authentication
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :authorize_event, only: [:edit, :update, :destroy]

  # GET /events
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @view = params[:view] || 'month'

    date_range = case @view
    when 'week' then @date.beginning_of_week..@date.end_of_week
    when 'day' then @date.beginning_of_day..@date.end_of_day
    else @date.beginning_of_month..@date.end_of_month
    end

    @events = Event.visible_to(current_user)
                   .between(date_range.begin, date_range.end)
                   .includes(:created_by, :event_rsvps)

    # Expand recurring events
    @events = expand_recurring_events(@events, date_range)
  end

  # GET /events/:id
  def show
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /events/new
  def new
    @event = Event.new(start_at: params[:start_at] || Time.current)

    respond_to do |format|
      format.html
      format.turbo_stream { render layout: false }
    end
  end

  # POST /events
  def create
    @event = current_user.created_events.build(event_params)

    respond_to do |format|
      if @event.save
        create_default_reminder if params[:add_reminder]
        format.html { redirect_to events_path, notice: 'Event created.' }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /events/:id/edit
  def edit
    respond_to do |format|
      format.html
      format.turbo_stream { render layout: false }
    end
  end

  # PATCH /events/:id
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to events_path, notice: 'Event updated.' }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/:id
  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_path, notice: 'Event deleted.' }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@event) }
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_event
    unless @event.created_by == current_user || current_user.admin?
      redirect_to events_path, alert: 'Not authorized.'
    end
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :start_at, :end_at, :all_day,
      :color, :visibility, :recurrence_rule, :recurrence_end_at
    )
  end

  def expand_recurring_events(events, date_range)
    expanded = []
    events.each do |event|
      if event.recurring?
        expanded.concat(event.occurrences_between(date_range.begin, date_range.end))
      else
        expanded << event
      end
    end
    expanded.sort_by(&:start_at)
  end

  def create_default_reminder
    @event.event_reminders.create(
      user: current_user,
      minutes_before: params[:reminder_minutes] || 60
    )
  end
end
