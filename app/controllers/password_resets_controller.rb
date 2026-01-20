# frozen_string_literal: true

# PasswordResetsController handles user self-service password resets
#
# This allows users who have forgotten their password to request a reset.
# For now, the temporary password is displayed directly (email integration
# will be added later).
#
class PasswordResetsController < ApplicationController
  # No authentication required for password reset (user is locked out)
  # Redirect logged-in users away from this page
  before_action :redirect_if_logged_in

  # GET /password_resets/new
  def new
  end

  # POST /password_resets
  def create
    @email = params[:email]&.downcase&.strip
    @user = User.find_by(email: @email)

    if @user.nil?
      # Don't reveal whether the email exists for security
      flash.now[:alert] = "If an account with that email exists, a password reset has been initiated."
      render :new, status: :unprocessable_entity
      return
    end

    if @user.removed?
      # Don't reveal that the account was removed
      flash.now[:alert] = "If an account with that email exists, a password reset has been initiated."
      render :new, status: :unprocessable_entity
      return
    end

    # Generate and set temporary password
    @temporary_password = User.generate_temporary_password
    @user.update!(password: @temporary_password, password_changed: false)

    # TODO: Send email with new temporary password
    # UserMailer.password_reset(@user, @temporary_password).deliver_later

    # For now, display the temporary password directly
    # In production, this would redirect to a "check your email" page
    render :show
  end

  private

  def redirect_if_logged_in
    redirect_to dashboard_path if logged_in?
  end
end
