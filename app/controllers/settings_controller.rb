# frozen_string_literal: true

# SettingsController handles user preferences and settings
#
class SettingsController < ApplicationController
  before_action :require_authentication

  # GET /settings
  def show
    @user = current_user
  end

  # PATCH /settings
  def update
    @user = current_user

    if @user.update(settings_params)
      redirect_to settings_path, notice: "Settings updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(
      :color_mode,
      :selected_theme_id,
      :notify_in_app,
      :notify_email,
      :notify_push
    )
  end
end
