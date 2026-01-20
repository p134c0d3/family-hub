# frozen_string_literal: true

module Admin
  # AccessRequestsController handles admin review of access requests
  #
  class AccessRequestsController < BaseController
    before_action :set_access_request, only: [:show, :approve, :deny]

    # GET /admin/access_requests
    def index
      @pending_requests = AccessRequest.pending.recent
      @approved_requests = AccessRequest.approved.recent.limit(10)
      @denied_requests = AccessRequest.denied.recent.limit(10)
    end

    # GET /admin/access_requests/:id
    def show
    end

    # POST /admin/access_requests/:id/approve
    def approve
      @temporary_password = params[:temporary_password].presence || User.generate_temporary_password

      if (@user = @access_request.approve!(current_user, @temporary_password))
        # TODO: Send email with temporary password
        # UserMailer.access_approved(@access_request, @temporary_password).deliver_later

        render :approved
      else
        flash[:alert] = @access_request.errors.full_messages.join(", ")
        render :show, status: :unprocessable_entity
      end
    end

    # POST /admin/access_requests/:id/deny
    def deny
      if @access_request.deny!(current_user)
        # TODO: Send denial email
        # UserMailer.access_denied(@access_request).deliver_later

        flash[:notice] = "Request denied."
        redirect_to admin_access_requests_path
      else
        flash[:alert] = "Failed to deny request."
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_access_request
      @access_request = AccessRequest.find(params[:id])
    end
  end
end
