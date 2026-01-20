# frozen_string_literal: true

# MediaItemsController handles photos, videos, and documents
#
class MediaItemsController < ApplicationController
  before_action :require_authentication

  def index
    @media_items = []
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
