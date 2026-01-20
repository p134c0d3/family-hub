# frozen_string_literal: true

# EventsController handles calendar events
#
class EventsController < ApplicationController
  before_action :require_authentication

  def index
    @events = []
  end

  def show
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
