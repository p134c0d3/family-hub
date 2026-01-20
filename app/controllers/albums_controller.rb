# frozen_string_literal: true

# AlbumsController handles photo/video albums
#
class AlbumsController < ApplicationController
  before_action :require_authentication

  def index
    @albums = []
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
