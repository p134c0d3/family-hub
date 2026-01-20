# frozen_string_literal: true

# Authentication concern for controllers
#
# Provides session-based authentication with helper methods for
# logging in, logging out, and checking authentication status.
#
# Include in ApplicationController to make authentication available
# throughout the application.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    helper_method :current_user, :logged_in?
  end

  private

  # Set the current user from the session
  def set_current_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id], status: 'active')

      # Clear session if user not found or inactive
      if @current_user.nil?
        session.delete(:user_id)
      end
    end
  end

  # Returns the currently logged in user (or nil)
  def current_user
    @current_user
  end

  # Check if a user is logged in
  def logged_in?
    current_user.present?
  end

  # Log in a user by storing their ID in the session
  def log_in(user)
    session[:user_id] = user.id
    @current_user = user

    # Set encrypted cookie for ActionCable authentication
    cookies.encrypted[:user_id] = {
      value: user.id,
      httponly: true,
      same_site: :lax
    }
  end

  # Log out the current user
  def log_out
    session.delete(:user_id)
    cookies.delete(:user_id)
    @current_user = nil
  end

  # Require authentication for protected routes
  # Use: before_action :require_authentication
  def require_authentication
    unless logged_in?
      store_location
      redirect_to login_path, alert: "Please log in to continue."
    end
  end

  # Require that no user is logged in (for login/signup pages)
  # Use: before_action :require_no_authentication
  def require_no_authentication
    if logged_in?
      redirect_to dashboard_path
    end
  end

  # Require the user to change their password (for temp password flow)
  # Use: before_action :require_password_change
  def require_password_change
    if logged_in? && !current_user.password_changed?
      redirect_to change_password_path, alert: "Please change your password to continue."
    end
  end

  # Skip password change requirement for certain actions
  def skip_password_change_check
    # Override this in controllers where needed
  end

  # Store the requested URL for redirect after login
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  # Redirect to stored location or default
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end
end
