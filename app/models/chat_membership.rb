# frozen_string_literal: true

# ChatMembership model
#
# Join model between Chat and User, tracking membership and read state.
#
class ChatMembership < ApplicationRecord
  # Associations
  belongs_to :chat
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :chat_id, message: "is already a member of this chat" }

  # Scopes
  scope :with_notifications, -> { where(notifications_enabled: true) }
  scope :unread, -> { where('last_read_at IS NULL OR last_read_at < ?', Time.current) }

  # Instance methods

  # Check if there are unread messages
  def unread_messages?
    return true if last_read_at.nil?

    chat.messages.where('created_at > ?', last_read_at).where.not(user: user).exists?
  end

  # Get unread message count
  def unread_count
    return chat.messages.where.not(user: user).count if last_read_at.nil?

    chat.messages.where('created_at > ?', last_read_at).where.not(user: user).count
  end

  # Mark as read
  def mark_as_read!
    update(last_read_at: Time.current)
  end

  # Toggle notifications
  def toggle_notifications!
    update(notifications_enabled: !notifications_enabled)
  end
end
