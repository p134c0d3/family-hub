# frozen_string_literal: true

# ThemeGalleryController handles theme browsing and selection for users
#
# Endpoints:
#   GET /theme_gallery - List all active themes with current theme highlighted
#   GET /theme_gallery/:id/preview - Return theme CSS as JSON for live preview
#   POST /theme_gallery/:id/select - Update current user's theme selection
#
class ThemeGalleryController < ApplicationController
  before_action :require_authentication

  # GET /theme_gallery
  # Display all active themes with the current user's selected theme
  def index
    @themes = Theme.active.order(:name)
    @current_theme = current_user.effective_theme
  end

  # GET /theme_gallery/:id/preview
  # Show a visual preview of the theme in a modal
  def preview
    @theme = Theme.find(params[:id])
  end

  # POST /theme_gallery/:id/select
  # Update the current user's theme selection
  def select
    @theme = Theme.find(params[:id])
    current_user.update(theme: @theme)
    redirect_to theme_gallery_index_path, notice: "Theme changed to #{@theme.name}."
  end
end
