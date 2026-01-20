# frozen_string_literal: true

module Admin
  # BaseController for all admin controllers
  #
  # Ensures only admins can access admin routes.
  #
  class BaseController < ApplicationController
    before_action :require_authentication
    before_action :require_admin

    layout "admin"
  end
end
