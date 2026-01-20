# frozen_string_literal: true

# CalendarController handles the calendar view
#
# Displays events in a monthly calendar format with
# navigation and quick event creation.
#
class CalendarController < ApplicationController
  before_action :require_authentication

  # GET /calendar
  def show
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    # TODO: Load events for the month
    @events = []
  end
end
