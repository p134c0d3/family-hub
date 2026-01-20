# frozen_string_literal: true

# Authorization concern for controllers
#
# Provides role-based authorization checks for admin and member roles.
# Works in conjunction with the Authentication concern.
module Authorization
  extend ActiveSupport::Concern

  private

  # Require admin role for access
  # Use: before_action :require_admin
  def require_admin
    unless current_user&.admin?
      if request.xhr? || request.format.json?
        head :forbidden
      else
        redirect_to dashboard_path, alert: "You don't have permission to access this page."
      end
    end
  end

  # Check if current user is an admin
  def admin?
    current_user&.admin?
  end

  # Authorize that the current user can manage a resource
  # Override in controllers for custom authorization logic
  def authorize_resource(resource)
    unless can_manage?(resource)
      if request.xhr? || request.format.json?
        head :forbidden
      else
        redirect_to dashboard_path, alert: "You don't have permission to perform this action."
      end
    end
  end

  # Default can_manage? check - override in specific controllers
  def can_manage?(resource)
    return false unless current_user

    # Admins can manage everything
    return true if current_user.admin?

    # Check if the resource belongs to the current user
    if resource.respond_to?(:user_id)
      resource.user_id == current_user.id
    elsif resource.respond_to?(:created_by_id)
      resource.created_by_id == current_user.id
    elsif resource.respond_to?(:uploaded_by_id)
      resource.uploaded_by_id == current_user.id
    else
      false
    end
  end
end
