# frozen_string_literal: true

# GalleryController handles the main gallery view
#
# Displays media items in a timeline (reverse chronological)
# with filtering options.
#
class GalleryController < ApplicationController
  before_action :require_authentication

  # GET /gallery
  def index
    # TODO: Load media items
    @media_items = []
  end
end
