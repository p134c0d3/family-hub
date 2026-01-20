# frozen_string_literal: true

# SessionsController handles user authentication (login/logout)
#
# Login flow:
# 1. User enters email and password
# 2. System authenticates credentials
# 3. If valid, user is logged in (session created)
# 4. If user has temp password, redirect to change password page
# 5. Otherwise, redirect to dashboard
#
class SessionsController < ApplicationController
  # Skip authentication for login page
  skip_before_action :set_current_user, only: [:new, :create]

  # Require user to NOT be logged in for login page
  before_action :redirect_if_logged_in, only: [:new, :create]

  # GET /login
  def new
    # Render login form
  end

  # POST /login
  def create
    user = User.authenticate(params[:email], params[:password])

    if user
      log_in(user)

      # Check if user needs to change password
      if !user.password_changed?
        redirect_to change_password_path, notice: "Please set a new password."
      else
        redirect_back_or(dashboard_path)
        flash[:notice] = "Welcome back, #{user.first_name}!"
      end
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    log_out
    redirect_to login_path, notice: "You have been logged out."
  end

  private

  def redirect_if_logged_in
    redirect_to dashboard_path if logged_in?
  end
end
