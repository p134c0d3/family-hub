# frozen_string_literal: true

module Admin
  # DashboardController handles the admin dashboard
  #
  class DashboardController < BaseController
    # GET /admin
    def show
      @pending_requests_count = 0 # TODO: AccessRequest.pending.count
      @active_users_count = User.active.count
      @total_users_count = User.count
    end
  end
end
