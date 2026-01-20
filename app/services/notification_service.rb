# frozen_string_literal: true

# NotificationService handles creating notifications for various events.
#
# Usage:
#   NotificationService.create_thread_reply_notification(message)
#
class NotificationService
  class << self
    # Create a notification when someone replies to a message thread
    # Notifies the original message author that someone replied
    def create_thread_reply_notification(message)
      return unless message.reply?

      parent_message = message.parent_message
      return if parent_message.nil?

      # Don't notify if replying to your own message
      return if parent_message.user_id == message.user_id

      # Don't notify if parent message was deleted
      return if parent_message.deleted?

      # Check if user should receive notifications
      return unless parent_message.user.should_receive_notification?(message.chat)

      # Don't create duplicate notifications for the same reply
      return if Notification.exists?(
        user: parent_message.user,
        actor: message.user,
        notifiable: message,
        notification_type: 'thread_reply'
      )

      Notification.create!(
        user: parent_message.user,
        actor: message.user,
        notifiable: message,
        notification_type: 'thread_reply'
      )
    end
  end
end
