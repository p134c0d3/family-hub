# frozen_string_literal: true

# NotificationsController handles listing and managing notifications
#
# Endpoints:
#   GET /notifications - List recent notifications (JSON)
#   PATCH /notifications/:id/mark_read - Mark single notification as read
#   POST /notifications/mark_all_read - Mark all notifications as read
#
class NotificationsController < ApplicationController
  before_action :require_authentication
  before_action :set_notification, only: [:mark_read]

  # GET /notifications
  # Returns recent notifications for the current user as JSON
  def index
    @notifications = current_user.notifications
                                 .includes(:actor, :notifiable)
                                 .recent
                                 .limit(50)

    render json: {
      notifications: @notifications.map { |n| notification_json(n) },
      unread_count: current_user.notifications.unread.count
    }
  end

  # PATCH /notifications/:id/mark_read
  # Mark a single notification as read
  def mark_read
    @notification.mark_read!

    render json: {
      success: true,
      unread_count: current_user.notifications.unread.count
    }
  end

  # POST /notifications/mark_all_read
  # Mark all notifications as read
  def mark_all_read
    Notification.mark_all_read_for(current_user)

    render json: {
      success: true,
      unread_count: 0
    }
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_json(notification)
    {
      id: notification.id,
      notification_type: notification.notification_type,
      description: notification.description,
      actor_name: notification.actor.first_name,
      actor_avatar_url: notification.actor.avatar.attached? ? url_for(notification.actor.avatar) : nil,
      chat_id: notification.chat&.id,
      message_id: notification.notifiable_id,
      read: notification.read?,
      created_at: notification.created_at.iso8601,
      time_ago: time_ago_in_words(notification.created_at)
    }
  end

  def time_ago_in_words(time)
    distance = Time.current - time

    case distance
    when 0..59
      "just now"
    when 60..3599
      "#{(distance / 60).to_i}m ago"
    when 3600..86399
      "#{(distance / 3600).to_i}h ago"
    else
      "#{(distance / 86400).to_i}d ago"
    end
  end
end
