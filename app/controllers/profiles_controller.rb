# frozen_string_literal: true

# ProfilesController handles user profile viewing and editing
#
class ProfilesController < ApplicationController
  before_action :require_authentication
  before_action :set_user

  # GET /profile
  def show
  end

  # GET /profile/edit
  def edit
  end

  # PATCH /profile
  def update
    respond_to do |format|
      if @user.update(profile_params)
        format.html { redirect_to profile_path, notice: "Profile updated successfully." }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /profile/update_avatar
  def update_avatar
    if params[:avatar].present? && @user.avatar.attach(params[:avatar])
      redirect_to profile_path, notice: "Avatar updated successfully."
    else
      redirect_to edit_profile_path, alert: "Failed to update avatar."
    end
  end

  # PATCH /profile/update_password
  def update_password
    if @user.authenticate(params[:current_password])
      if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        redirect_to profile_path, notice: "Password changed successfully."
      else
        flash.now[:alert] = @user.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Current password is incorrect."
      render :edit, status: :unprocessable_entity
    end
  end

  # PATCH /profile/update_notifications
  def update_notifications
    prefs = params[:notification_preferences]&.to_unsafe_h || {}

    respond_to do |format|
      if @user.update(notification_preferences: prefs)
        format.html { redirect_to profile_path, notice: "Notification preferences updated." }
        format.turbo_stream
      else
        format.html { redirect_to profile_path, alert: "Failed to update notification preferences." }
      end
    end
  end

  # PATCH /profile/update_theme
  def update_theme
    theme = Theme.find_by(id: params[:theme_id])

    respond_to do |format|
      if theme && @user.update(theme: theme)
        format.html { redirect_to profile_path, notice: "Theme updated successfully." }
        format.turbo_stream
      else
        format.html { redirect_to profile_path, alert: "Failed to update theme." }
      end
    end
  end

  # PATCH /profile/update_color_mode (legacy support)
  def update_color_mode
    if @user.update(color_mode: params[:color_mode])
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email, :phone, :address, :birthday, :bio, :city, :date_of_birth)
  end
end
