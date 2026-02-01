# frozen_string_literal: true

# CalendarController handles the calendar view
#
# Displays events in a monthly calendar format with
# navigation and quick event creation.
#
# Supports multiple view modes (month, week, day) and
# Turbo Stream responses for navigation.
#
class CalendarController < ApplicationController
  before_action :require_authentication

  # GET /calendar
  def show
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @view = params[:view] || 'month'

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
