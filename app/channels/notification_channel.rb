# frozen_string_literal: true

# NotificationChannel handles real-time notifications for users
#
# Each user subscribes to their own notification stream.
# Notifications are broadcast when:
#   - Someone mentions them with @Name
#   - Someone replies to their message thread
#
# Broadcasts:
#   - new_notification: When a notification is created
#   - notification_read: When a notification is marked as read
#   - notifications_read: When multiple notifications are marked as read
#
class NotificationChannel < ApplicationCable::Channel
  # Subscribe to the current user's notification stream
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end

  # Mark a notification as read
  def mark_read(data)
    notification = current_user.notifications.find_by(id: data['notification_id'])
    notification&.mark_read!
  end

  # Mark all notifications as read
  def mark_all_read
    Notification.mark_all_read_for(current_user)
  end
end
