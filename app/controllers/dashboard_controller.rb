# frozen_string_literal: true

# DashboardController handles the main dashboard/home page
#
# The dashboard provides a unified view of:
# - Recent chat activity
# - Upcoming calendar events
# - Latest gallery items
#
class DashboardController < ApplicationController
  before_action :require_authentication
  before_action :require_password_changed

  # GET /dashboard (or root when logged in)
  def show
    @recent_chats = Chat.for_user(current_user).with_recent_activity.limit(5)

    # Load events if the model exists (future sprint)
    @upcoming_events = if defined?(Event)
                         Event.where('starts_at >= ?', Time.current).order(starts_at: :asc).limit(5)
                       else
                         []
                       end

    # Load media if the model exists (future sprint)
    @recent_media = if defined?(MediaItem)
                      MediaItem.order(created_at: :desc).limit(8)
                    else
                      []
                    end
  end

  private

  def require_password_changed
    unless current_user.password_changed?
      redirect_to change_password_path, alert: "Please change your password to continue."
    end
  end
end
