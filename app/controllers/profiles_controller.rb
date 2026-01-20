# frozen_string_literal: true

# ProfilesController handles user profile viewing and editing
#
class ProfilesController < ApplicationController
  before_action :require_authentication

  # GET /profile
  def show
    @user = current_user
  end

  # GET /profile/edit
  def edit
    @user = current_user
  end

  # PATCH /profile
  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # PATCH /profile/update_color_mode
  def update_color_mode
    if current_user.update(color_mode: params[:color_mode])
      head :ok
    else
      head :unprocessable_entity
    end
  end

  # PATCH /profile/update_avatar
  def update_avatar
    if params[:avatar].present? && current_user.avatar.attach(params[:avatar])
      redirect_to profile_path, notice: "Avatar updated successfully."
    else
      redirect_to profile_path, alert: "Failed to update avatar."
    end
  end

  private

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :city, :date_of_birth)
  end
end
