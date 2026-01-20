# frozen_string_literal: true

# AccessRequestsController handles new user access requests
#
# This is the public-facing controller for potential users to
# submit their request to join the family hub.
#
class AccessRequestsController < ApplicationController
  # Skip authentication - this is public
  skip_before_action :set_current_user

  # GET /access_requests/new
  def new
    @access_request = AccessRequest.new
  end

  # POST /access_requests
  def create
    @access_request = AccessRequest.new(access_request_params)

    if @access_request.save
      redirect_to access_request_path(@access_request),
                  notice: "Your request has been submitted. You'll receive an email when it's reviewed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /access_requests/:id
  def show
    @access_request = AccessRequest.find(params[:id])
  end

  private

  def access_request_params
    params.require(:access_request).permit(
      :email,
      :first_name,
      :last_name,
      :date_of_birth,
      :city
    )
  end
end
