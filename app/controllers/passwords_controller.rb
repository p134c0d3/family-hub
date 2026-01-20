# frozen_string_literal: true

# PasswordsController handles password changes
#
# This is used when:
# 1. User logs in with a temporary password (must change)
# 2. User wants to change their password from settings
#
class PasswordsController < ApplicationController
  before_action :require_authentication

  # GET /change_password
  def edit
    # Render change password form
  end

  # PATCH /change_password
  def update
    if current_user.authenticate(params[:current_password])
      if params[:password] == params[:password_confirmation]
        if current_user.update(password: params[:password], password_changed: true)
          redirect_to dashboard_path, notice: "Your password has been updated."
        else
          flash.now[:alert] = current_user.errors.full_messages.join(", ")
          render :edit, status: :unprocessable_entity
        end
      else
        flash.now[:alert] = "Password confirmation doesn't match."
        render :edit, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Current password is incorrect."
      render :edit, status: :unprocessable_entity
    end
  end
end
