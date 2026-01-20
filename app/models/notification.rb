# frozen_string_literal: true

# Notification model for Family Hub
#
# Represents a notification for a user, triggered by another user's action.
# Notifications can be for thread replies or @mentions.
#
# Types:
#   - thread_reply: Someone replied to your message
#   - mention: Someone mentioned you with @YourName
#
class Notification < ApplicationRecord
  # Notification types
  TYPES = %w[thread_reply mention].freeze

  # Associations
  belongs_to :user                                    # Recipient of the notification
  belongs_to :actor, class_name: 'User'               # User who triggered the notification
  belongs_to :notifiable, polymorphic: true           # The message being referenced

  # Validations
  validates :notification_type, presence: true, inclusion: { in: TYPES }

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :thread_replies, -> { where(notification_type: 'thread_reply') }
  scope :mentions, -> { where(notification_type: 'mention') }

  # Callbacks
  after_create_commit :broadcast_new_notification

  # Instance methods

  # Check if notification has been read
  def read?
    read_at.present?
  end

  # Check if notification is unread
  def unread?
    !read?
  end

  # Mark notification as read
  def mark_read!
    return if read?

    update(read_at: Time.current)
    broadcast_notification_read
  end

  # Get the chat this notification is about
  def chat
    notifiable.chat if notifiable.respond_to?(:chat)
  end

  # Human-readable description of the notification
  def description
    case notification_type
    when 'thread_reply'
      "#{actor.first_name} replied to your message"
    when 'mention'
      "#{actor.first_name} mentioned you"
    else
      "You have a new notification"
    end
  end

  # Class methods

  # Mark all unread notifications for a user as read
  def self.mark_all_read_for(user)
    unread_ids = user.notifications.unread.pluck(:id)
    user.notifications.unread.update_all(read_at: Time.current)

    # Broadcast the bulk read update
    NotificationChannel.broadcast_to(
      user,
      type: 'notifications_read',
      notification_ids: unread_ids
    )
  end

  private

  # Broadcast new notification via ActionCable
  def broadcast_new_notification
    NotificationChannel.broadcast_to(
      user,
      type: 'new_notification',
      notification: {
        id: id,
        notification_type: notification_type,
        description: description,
        actor_name: actor.first_name,
        actor_avatar_url: actor.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_path(actor.avatar, only_path: true) : nil,
        chat_id: chat&.id,
        message_id: notifiable_id,
        created_at: created_at.iso8601
      },
      unread_count: user.notifications.unread.count
    )
  end

  # Broadcast when notification is marked as read
  def broadcast_notification_read
    NotificationChannel.broadcast_to(
      user,
      type: 'notification_read',
      notification_id: id,
      unread_count: user.notifications.unread.count
    )
  end
end
